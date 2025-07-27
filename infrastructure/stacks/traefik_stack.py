from aws_cdk import (
    Stack,
    aws_ecs as ecs,
    aws_ecs_patterns as ecs_patterns,
    aws_ec2 as ec2,
    aws_elasticloadbalancingv2 as elbv2,
    aws_certificatemanager as acm,
    aws_route53 as route53,
    aws_route53_targets as targets,
    aws_logs as logs,
    aws_iam as iam,
    aws_ssm as ssm,
    Duration,
    RemovalPolicy,
)
from constructs import Construct
from .base_stack import BaseStack
from typing import Dict, Any

class TraefikStack(BaseStack):
    """Traefik reverse proxy stack for API Gateway."""
    
    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        config: Dict[str, Any],
        api_gateway_url: str,
        vpc: ec2.Vpc = None,
        **kwargs
    ) -> None:
        super().__init__(scope, construct_id, config, **kwargs)
        
        # Create or use existing VPC
        self.vpc = vpc or ec2.Vpc(
            self,
            "TraefikVpc",
            vpc_name=self.get_resource_name("traefik", "vpc", "main"),
            max_azs=2,
            nat_gateways=1 if self.environment != "dev" else 0,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="Public",
                    subnet_type=ec2.SubnetType.PUBLIC,
                    cidr_mask=24
                ),
                ec2.SubnetConfiguration(
                    name="Private",
                    subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS,
                    cidr_mask=24
                )
            ]
        )
        
        # Create ECS Cluster
        self.cluster = ecs.Cluster(
            self,
            "TraefikCluster",
            cluster_name=self.get_resource_name("traefik", "cluster", "main"),
            vpc=self.vpc,
            container_insights=True,
        )
        
        # Create Traefik task definition
        task_definition = ecs.FargateTaskDefinition(
            self,
            "TraefikTaskDef",
            family=self.get_resource_name("traefik", "task", "proxy"),
            memory_limit_mib=self.config.get("traefik", {}).get("memory", 512),
            cpu=self.config.get("traefik", {}).get("cpu", 256),
        )
        
        # Add ECS provider permissions
        task_definition.add_to_task_role_policy(
            iam.PolicyStatement(
                actions=[
                    "ecs:ListClusters",
                    "ecs:DescribeClusters",
                    "ecs:ListTasks",
                    "ecs:DescribeTasks",
                    "ecs:DescribeContainerInstances",
                    "ecs:DescribeTaskDefinition",
                    "ec2:DescribeInstances",
                ],
                resources=["*"]
            )
        )
        
        # Create log group
        log_group = logs.LogGroup(
            self,
            "TraefikLogs",
            log_group_name=f"/aws/ecs/{self.get_resource_name('traefik', 'logs', 'main')}",
            retention=logs.RetentionDays.ONE_WEEK if self.environment == "dev" else logs.RetentionDays.ONE_MONTH,
            removal_policy=RemovalPolicy.DESTROY,
        )
        
        # Add Traefik container
        container = task_definition.add_container(
            "traefik",
            image=ecs.ContainerImage.from_asset("traefik/docker"),
            logging=ecs.LogDrivers.aws_logs(
                stream_prefix="traefik",
                log_group=log_group,
            ),
            environment={
                "TRAEFIK_LOG_LEVEL": "INFO" if self.environment == "prd" else "DEBUG",
                "API_GATEWAY_URL": api_gateway_url,
                "ENVIRONMENT": self.environment,
            },
            health_check=ecs.HealthCheck(
                command=["CMD-SHELL", "wget -q --spider http://localhost:80/ping || exit 1"],
                interval=Duration.seconds(30),
                timeout=Duration.seconds(5),
                retries=3,
                start_period=Duration.seconds(60),
            ),
        )
        
        # Add port mappings
        container.add_port_mappings(
            ecs.PortMapping(container_port=80, protocol=ecs.Protocol.TCP),
            ecs.PortMapping(container_port=443, protocol=ecs.Protocol.TCP),
            ecs.PortMapping(container_port=8080, protocol=ecs.Protocol.TCP),  # Dashboard
        )
        
        # Create certificate (if domain provided)
        certificate = None
        if self.config.get("domain_name"):
            hosted_zone = route53.HostedZone.from_lookup(
                self,
                "HostedZone",
                domain_name=self.config["domain_name"]
            )
            
            certificate = acm.Certificate(
                self,
                "TraefikCertificate",
                domain_name=f"*.{self.config['domain_name']}",
                validation=acm.CertificateValidation.from_dns(hosted_zone),
            )
        
        # Create Fargate service with ALB
        fargate_service = ecs_patterns.ApplicationLoadBalancedFargateService(
            self,
            "TraefikService",
            cluster=self.cluster,
            task_definition=task_definition,
            service_name=self.get_resource_name("traefik", "service", "proxy"),
            desired_count=self.config.get("traefik", {}).get("desired_count", 2),
            public_load_balancer=True,
            certificate=certificate,
            domain_name=f"api.{self.config['domain_name']}" if self.config.get("domain_name") else None,
            domain_zone=hosted_zone if self.config.get("domain_name") else None,
            listener_port=443 if certificate else 80,
            redirect_http=True if certificate else False,
            assign_public_ip=True,
        )
        
        # Configure health check
        fargate_service.target_group.configure_health_check(
            path="/ping",
            healthy_http_codes="200",
            interval=Duration.seconds(30),
            timeout=Duration.seconds(10),
            healthy_threshold_count=2,
            unhealthy_threshold_count=3,
        )
        
        # Auto-scaling configuration
        scaling = fargate_service.service.auto_scale_task_count(
            min_capacity=self.config.get("traefik", {}).get("min_capacity", 1),
            max_capacity=self.config.get("traefik", {}).get("max_capacity", 10),
        )
        
        scaling.scale_on_cpu_utilization(
            "CpuScaling",
            target_utilization_percent=70,
            scale_in_cooldown=Duration.seconds(60),
            scale_out_cooldown=Duration.seconds(60),
        )
        
        scaling.scale_on_request_count(
            "RequestCountScaling",
            requests_per_target=1000,
            scale_in_cooldown=Duration.seconds(60),
            scale_out_cooldown=Duration.seconds(60),
        )
        
        # Store outputs in SSM
        ssm.StringParameter(
            self,
            "TraefikUrlParameter",
            parameter_name=f"/{self.company_code}/{self.environment}/traefik/url",
            string_value=f"https://{fargate_service.load_balancer.load_balancer_dns_name}",
        )
        
        # Outputs
        self.traefik_url = fargate_service.load_balancer.load_balancer_dns_name
        self.vpc = self.vpc

#!/bin/bash

# Traefik Integration for Lambda Monorepo
# This script adds Traefik reverse proxy to your existing serverless architecture

echo "🚀 Adding Traefik to Lambda Monorepo..."

# Create Traefik directory structure
echo "📁 Creating Traefik directories..."
mkdir -p traefik/{config,docker}
mkdir -p infrastructure/stacks

# Create Traefik Dockerfile
echo "🐳 Creating Traefik Docker configuration..."
cat > traefik/docker/Dockerfile << 'EOF'
FROM traefik:v3.0

# Copy Traefik configuration
COPY traefik.yaml /etc/traefik/traefik.yaml
COPY dynamic/ /etc/traefik/dynamic/

# Expose ports
EXPOSE 80 443 8080

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
  CMD ["traefik", "healthcheck"]
EOF

# Create main Traefik configuration
cat > traefik/config/traefik.yaml << 'EOF'
# Traefik Static Configuration
global:
  checkNewVersion: true
  sendAnonymousUsage: false

serversTransport:
  insecureSkipVerify: true

api:
  dashboard: true
  debug: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  file:
    directory: /etc/traefik/dynamic
    watch: true
  ecs:
    autoDiscoverClusters: true
    region: us-east-1
    exposedByDefault: false

metrics:
  prometheus:
    buckets:
      - 0.1
      - 0.3
      - 1.2
      - 5.0

log:
  level: INFO
  format: json

accessLog:
  format: json
  fields:
    defaultMode: keep
    headers:
      defaultMode: drop
      names:
        User-Agent: keep
        Authorization: drop

ping:
  entryPoint: web
EOF

# Create dynamic configuration for API Gateway routing
mkdir -p traefik/config/dynamic
cat > traefik/config/dynamic/api-gateway.yaml << 'EOF'
# Dynamic Configuration for API Gateway
http:
  routers:
    api-gateway:
      rule: "Host(`api.yourdomain.com`)"
      entryPoints:
        - websecure
      service: api-gateway-service
      tls:
        certResolver: letsencrypt
      middlewares:
        - rate-limit
        - cors
        - circuit-breaker
        - retry

  services:
    api-gateway-service:
      loadBalancer:
        servers:
          - url: "https://your-api-gateway-id.execute-api.us-east-1.amazonaws.com"
        healthCheck:
          path: /health
          interval: 30s
          timeout: 5s

  middlewares:
    rate-limit:
      rateLimit:
        average: 100
        burst: 200
        period: 1m
        sourceCriterion:
          ipStrategy:
            depth: 2

    cors:
      headers:
        accessControlAllowMethods:
          - GET
          - POST
          - PUT
          - DELETE
          - OPTIONS
        accessControlAllowHeaders:
          - "*"
        accessControlAllowOriginList:
          - "*"
        accessControlMaxAge: 100
        addVaryHeader: true

    circuit-breaker:
      circuitBreaker:
        expression: "NetworkErrorRatio() > 0.5 || ResponseCodeRatio(500, 600, 0, 600) > 0.5"
        checkPeriod: 10s
        fallbackDuration: 10s
        recoveryDuration: 10s

    retry:
      retry:
        attempts: 3
        initialInterval: 100ms

tls:
  certificates:
    - certFile: /etc/traefik/certs/cert.pem
      keyFile: /etc/traefik/certs/key.pem
EOF

# Create Traefik CDK Stack
cat > infrastructure/stacks/traefik_stack.py << 'EOF'
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
EOF

# Update the main CDK app to include Traefik
cat > infrastructure/app_update.py << 'EOF'
# Add this to your existing app.py after the layer_stack creation:

from stacks.traefik_stack import TraefikStack

# Create Traefik stack
traefik_stack = TraefikStack(
    app,
    f"{config['company_code']}-{env}-traefik-stack",
    config=config,
    api_gateway_url=lambda_stack.api_url,  # You'll need to expose this from lambda_stack
    env=cdk.Environment(
        account=os.getenv("CDK_DEFAULT_ACCOUNT"),
        region=config["region"]
    )
)

traefik_stack.add_dependency(lambda_stack)
EOF

# Create Traefik-specific configuration
cat > config/traefik.yaml << 'EOF'
# Traefik-specific configuration
traefik:
  # ECS Task Configuration
  cpu: 256
  memory: 512
  desired_count: 2
  min_capacity: 1
  max_capacity: 10
  
  # Traefik Configuration
  dashboard_enabled: true
  metrics_enabled: true
  access_logs_enabled: true
  
  # Rate Limiting
  rate_limit:
    average: 100
    burst: 200
    period: "1m"
  
  # Circuit Breaker
  circuit_breaker:
    expression: "NetworkErrorRatio() > 0.5"
    check_period: "10s"
    fallback_duration: "10s"
    recovery_duration: "10s"
  
  # Retry Policy
  retry:
    attempts: 3
    initial_interval: "100ms"
  
  # Health Check
  health_check:
    interval: "30s"
    timeout: "5s"
    path: "/health"

# Domain configuration (optional)
domain_name: "yourdomain.com"  # Set to null if not using custom domain
EOF

# Create Traefik middleware configurations
cat > traefik/config/dynamic/middleware.yaml << 'EOF'
# Additional middleware configurations
http:
  middlewares:
    # Security headers
    security-headers:
      headers:
        frameDeny: true
        sslRedirect: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 315360000
        customResponseHeaders:
          X-Forwarded-Proto: https
    
    # Compression
    compress:
      compress: {}
    
    # Request ID
    request-id:
      plugin:
        requestid:
          headerName: "X-Request-ID"
    
    # API Gateway specific headers
    api-gateway-headers:
      headers:
        customRequestHeaders:
          X-Forwarded-Host: "api.yourdomain.com"
          X-Real-IP: "true"
EOF

# Create monitoring configuration
cat > traefik/config/dynamic/monitoring.yaml << 'EOF'
# Monitoring endpoints
http:
  routers:
    prometheus:
      rule: "Path(`/metrics`)"
      service: prometheus@internal
      entryPoints:
        - web
      middlewares:
        - auth
    
    dashboard:
      rule: "(PathPrefix(`/api`) || PathPrefix(`/dashboard`))"
      service: api@internal
      entryPoints:
        - web
      middlewares:
        - auth
  
  middlewares:
    auth:
      basicAuth:
        users:
          - "admin:$2y$10$..." # Generate with: htpasswd -nb admin password
EOF

# Create docker-compose for local testing
cat > traefik/docker-compose.yaml << 'EOF'
version: '3.8'

services:
  traefik:
    build:
      context: docker
      dockerfile: Dockerfile
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - ./config/traefik.yaml:/etc/traefik/traefik.yaml:ro
      - ./config/dynamic:/etc/traefik/dynamic:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - TRAEFIK_LOG_LEVEL=DEBUG
      - API_GATEWAY_URL=https://your-api-gateway-id.execute-api.us-east-1.amazonaws.com
    networks:
      - traefik
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(`traefik.localhost`)"
      - "traefik.http.routers.dashboard.service=api@internal"
      - "traefik.http.routers.dashboard.entrypoints=web"

networks:
  traefik:
    external: true
EOF

# Update Makefile
cat >> Makefile << 'EOF'

# Traefik targets
.PHONY: build-traefik deploy-traefik test-traefik-local

# Build Traefik Docker image
build-traefik:
	docker build -t traefik-proxy:latest traefik/docker/

# Deploy Traefik stack
deploy-traefik: build-traefik
	cd infrastructure && cdk deploy $(COMPANY_CODE)-$(ENVIRONMENT)-traefik-stack

# Test Traefik locally
test-traefik-local:
	docker network create traefik || true
	docker-compose -f traefik/docker-compose.yaml up

# Full deployment with Traefik
deploy-all: build-layer package-lambdas build-traefik
	cd infrastructure && cdk deploy --all
EOF

# Create Traefik governance documentation
cat > governance/traefik-governance.md << 'EOF'
# Traefik Governance and Best Practices

## Overview
This document outlines governance policies for Traefik reverse proxy deployment.

## Configuration Management

### 1. Static vs Dynamic Configuration
- **Static Configuration**: Infrastructure settings (ports, providers, logs)
- **Dynamic Configuration**: Routing rules, middlewares, services

### 2. Security Policies

#### TLS Configuration
- Minimum TLS version: 1.2
- Strong cipher suites only
- HSTS enabled with preload

#### Authentication
- Dashboard requires authentication
- API endpoints protected by API Gateway authorizer
- Metrics endpoint requires basic auth

### 3. Rate Limiting

Default limits per environment:
- **Development**: 100 req/min average, 200 burst
- **Staging**: 500 req/min average, 1000 burst  
- **Production**: 1000 req/min average, 2000 burst

### 4. Circuit Breaker

Triggers when:
- Network error ratio > 50%
- 5xx response ratio > 50%

Recovery after 10 seconds of stability.

### 5. Monitoring Requirements

#### Metrics
- Prometheus metrics exposed on `/metrics`
- CloudWatch metrics via ECS integration
- Custom metrics for business KPIs

#### Logging
- Structured JSON logs
- Exclude sensitive headers (Authorization)
- Retain for compliance period

### 6. Scaling Policies

#### Auto-scaling triggers:
- CPU utilization > 70%
- Request count > 1000/target
- Response time > 2s (p95)

#### Capacity planning:
- Min: 1 (dev), 2 (staging), 3 (production)
- Max: 10 (configurable)

## Deployment Checklist

- [ ] TLS certificates valid and auto-renewing
- [ ] Health checks configured and passing
- [ ] Rate limiting appropriate for environment
- [ ] Circuit breaker thresholds reviewed
- [ ] Monitoring dashboards created
- [ ] Runbook updated with Traefik procedures
- [ ] Cost analysis completed
- [ ] Performance testing completed
EOF

# Create README for Traefik
cat > traefik/README.md << 'EOF'
# Traefik Reverse Proxy

This directory contains the Traefik configuration for the Lambda monorepo.

## Architecture

```
Internet → ALB → Traefik (ECS) → API Gateway → Lambda
```

## Key Features

- **Advanced Routing**: Path and host-based routing rules
- **Rate Limiting**: Protect backend services from overload
- **Circuit Breaker**: Automatic failover and recovery
- **Observability**: Prometheus metrics and structured logs
- **Security**: TLS termination, security headers, authentication

## Local Development

```bash
# Start Traefik locally
make test-traefik-local

# View dashboard at http://traefik.localhost
```

## Configuration

- Static config: `config/traefik.yaml`
- Dynamic routing: `config/dynamic/*.yaml`
- Environment-specific: `../../config/traefik.yaml`

## Monitoring

- Dashboard: https://your-alb-url/dashboard
- Metrics: https://your-alb-url/metrics
- Health: https://your-alb-url/ping

## Troubleshooting

1. **503 Service Unavailable**
   - Check API Gateway URL in dynamic config
   - Verify security groups allow egress to API Gateway
   - Check circuit breaker status

2. **Rate Limit Exceeded**
   - Review rate limit configuration
   - Check source IP for distributed requests
   - Consider increasing limits

3. **High Latency**
   - Check ECS task metrics
   - Review retry configuration
   - Verify API Gateway performance
EOF

echo "
✅ Traefik integration complete!

📋 Next Steps:
1. Update config/traefik.yaml with your domain
2. Set API Gateway URL in dynamic config
3. Generate admin password for dashboard
4. Review and adjust rate limits
5. Deploy: make deploy-traefik

🔧 Key Commands:
- Local testing:     make test-traefik-local
- Build image:       make build-traefik  
- Deploy Traefik:    make deploy-traefik
- Full deployment:   make deploy-all

📚 Documentation:
- Traefik setup: traefik/README.md
- Governance: governance/traefik-governance.md
- Configuration: traefik/config/

💡 Benefits:
- Advanced traffic management and routing
- Better observability with Prometheus metrics
- Cost optimization at high request volumes
- Protocol translation capabilities
- Unified entry point for multiple backends
"
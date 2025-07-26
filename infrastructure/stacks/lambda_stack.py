from aws_cdk import (
    Duration,
    aws_lambda as lambda_,
    aws_apigateway as apigw,
    aws_iam as iam,
    aws_logs as logs,
)
from constructs import Construct
from .base_stack import BaseStack
import os

class LambdaStack(BaseStack):
    def __init__(
        self, 
        scope: Construct, 
        construct_id: str,
        config: dict,
        layer_arn: str,
        **kwargs
    ) -> None:
        super().__init__(scope, construct_id, config, **kwargs)

        # Get the layer from ARN
        common_layer = lambda_.LayerVersion.from_layer_version_arn(
            self, "CommonLayer", layer_arn
        )

        # Create Lambda execution role
        lambda_role = iam.Role(
            self,
            "LambdaExecutionRole",
            role_name=self.get_resource_name("lambda", "role", "execution"),
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name("service-role/AWSLambdaBasicExecutionRole")
            ],
        )

        # Add SSM parameter read permissions
        lambda_role.add_to_policy(iam.PolicyStatement(
            actions=["ssm:GetParameter", "ssm:GetParameters"],
            resources=[f"arn:aws:ssm:{self.region}:{self.account}:parameter/{self.company_code}/{self.environment}/*"]
        ))

        # Create the authorizer Lambda
        authorizer_function = lambda_.Function(
            self,
            "AuthorizerFunction",
            function_name=self.get_resource_name("auth", "fn", "authorizer"),
            runtime=lambda_.Runtime.PYTHON_3_11,
            code=lambda_.Code.from_asset(
                os.path.join(os.path.dirname(__file__), "..", "..", "lambdas", "authorizer", "dist")
            ),
            handler="handler.lambda_handler",
            layers=[common_layer],
            timeout=Duration.seconds(self.config["lambda"]["timeout_seconds"]),
            memory_size=self.config["lambda"]["memory_size"],
            role=lambda_role,
            environment={
                "LOG_LEVEL": "INFO",
                "ENVIRONMENT": self.environment,
            },
            log_retention=logs.RetentionDays(self.config["lambda"]["log_retention_days"]),
        )

        # Create API Gateway authorizer
        authorizer = apigw.TokenAuthorizer(
            self,
            "ApiAuthorizer",
            handler=authorizer_function,
            identity_source="method.request.header.Authorization",
            validation_regex="^Bearer [-0-9a-zA-z\.]*$",
            results_cache_ttl=Duration.minutes(5),
        )

        # Create API Gateway
        api = apigw.RestApi(
            self,
            "ApiGateway",
            rest_api_name=self.get_resource_name("main", "api", "gateway"),
            description="API Gateway for Lambda functions",
            default_cors_preflight_options={
                "allow_origins": self.config["security"]["allowed_origins"],
                "allow_methods": apigw.Cors.ALL_METHODS,
                "allow_headers": ["Content-Type", "Authorization"],
            },
            deploy_options={
                "throttling_rate_limit": self.config["api_gateway"]["throttle_rate_limit"],
                "throttling_burst_limit": self.config["api_gateway"]["throttle_burst_limit"],
            }
        )

        # Add other Lambda functions here
        # Example: API handler
        api_handler = lambda_.Function(
            self,
            "ApiHandlerFunction",
            function_name=self.get_resource_name("api", "fn", "handler"),
            runtime=lambda_.Runtime.PYTHON_3_11,
            code=lambda_.Code.from_asset(
                os.path.join(os.path.dirname(__file__), "..", "..", "lambdas", "api_handler", "dist")
            ),
            handler="handler.lambda_handler",
            layers=[common_layer],
            timeout=Duration.seconds(self.config["lambda"]["timeout_seconds"]),
            memory_size=self.config["lambda"]["memory_size"],
            role=lambda_role,
            environment={
                "LOG_LEVEL": "INFO",
                "ENVIRONMENT": self.environment,
            },
        )

        # Add API endpoint with authorizer
        items = api.root.add_resource("items")
        items.add_method(
            "GET",
            apigw.LambdaIntegration(api_handler),
            authorizer=authorizer,
        )

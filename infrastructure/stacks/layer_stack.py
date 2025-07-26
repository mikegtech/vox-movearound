from aws_cdk import (
    aws_lambda as lambda_,
    aws_ssm as ssm,
)
from constructs import Construct
from .base_stack import BaseStack
import os

class LayerStack(BaseStack):
    def __init__(self, scope: Construct, construct_id: str, config: dict, **kwargs) -> None:
        super().__init__(scope, construct_id, config, **kwargs)

        # Create the common layer
        self.layer = lambda_.LayerVersion(
            self,
            "CommonLayer",
            code=lambda_.Code.from_asset(
                os.path.join(os.path.dirname(__file__), "..", "..", "layers", "common", "dist")
            ),
            compatible_runtimes=[lambda_.Runtime.PYTHON_3_11],
            description="Common utilities and dependencies for Lambda functions",
            layer_version_name=self.get_resource_name("common", "layer", "utils"),
        )

        # Store layer ARN in SSM for easy reference
        ssm.StringParameter(
            self,
            "CommonLayerArnParameter",
            parameter_name=f"/{self.company_code}/{self.environment}/lambda/layers/common/arn",
            string_value=self.layer.layer_version_arn,
        )

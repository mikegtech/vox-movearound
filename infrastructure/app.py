#!/usr/bin/env python3
import os
import yaml
from pathlib import Path
import aws_cdk as cdk
from stacks.lambda_stack import LambdaStack
from stacks.layer_stack import LayerStack
from stacks.traefik_stack import TraefikStack

# Load configuration
env = os.getenv("ENVIRONMENT", "dev")
config_path = Path(__file__).parent.parent / "config"

with open(config_path / "environments" / f"{env}.yaml", "r") as f:
    env_config = yaml.safe_load(f)

with open(config_path / "defaults.yaml", "r") as f:
    default_config = yaml.safe_load(f)

# Merge configs (environment overrides defaults)
config = {**default_config, **env_config}

app = cdk.App()

# Create stacks with proper configuration
layer_stack = LayerStack(
    app,
    f"{config["company_code"]}-{env}-layer-stack",
    config=config,
    env=cdk.Environment(
        account=os.getenv("CDK_DEFAULT_ACCOUNT"),
        region=config["region"]
    )
)


lambda_stack = LambdaStack(
    app,
    f"{config["company_code"]}-{env}-lambda-stack",
    config=config,
    layer_arn=layer_stack.layer.layer_version_arn,
    env=cdk.Environment(
        account=os.getenv("CDK_DEFAULT_ACCOUNT"),
        region=config["region"]
    )
)

lambda_stack.add_dependency(layer_stack)


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

app.synth()

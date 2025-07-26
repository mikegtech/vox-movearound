# Lambda Monorepo

AWS Lambda monorepo using Python, uvx package manager, and AWS CDK for deployment.

## Structure

```
.
├── infrastructure/          # AWS CDK infrastructure code
├── lambdas/                # Individual Lambda functions
├── layers/                 # Shared Lambda layers
├── governance/             # Policies and standards documentation
├── policies/               # IAM and resource policies
├── config/                 # Environment configurations
├── scripts/                # Build and deployment scripts
└── tests/                  # Integration tests
```

## Quick Start

```bash
# Install dependencies
make install

# Configure AWS credentials
export AWS_PROFILE=your-profile
export CDK_DEFAULT_ACCOUNT=123456789012
export CDK_DEFAULT_REGION=us-east-1
export ENVIRONMENT=dev

# Deploy infrastructure
make deploy
```

## Development Workflow

```bash
# Format code
make format

# Run linting
make lint

# Run tests
make test

# Validate governance policies
make governance-check

# Full pre-deployment validation
make pre-deploy
```

## Adding a New Lambda Function

1. Create a new directory under `lambdas/`:
   ```bash
   mkdir -p lambdas/my-function/tests
   ```

2. Add your Lambda handler and requirements

3. Update `infrastructure/stacks/lambda_stack.py` to include the new function

4. Deploy: `make deploy`

## Configuration

- Environment-specific configs in `config/environments/`
- Default values in `config/defaults.yaml`
- Override hierarchy: Environment config > Defaults

## Governance

- Naming conventions: `governance/naming-conventions.md`
- Tagging strategy: `governance/tagging-strategy.md`
- Compliance checklist: `governance/compliance-checklist.md`

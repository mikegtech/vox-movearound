#!/bin/bash

# Complete Remaining Lambda Monorepo Setup
# This finishes the setup after the initial script ran

echo "🔧 Completing Lambda Monorepo Setup..."

# Create remaining layer files
echo "📦 Creating layer files..."

cat > layers/common/pyproject.toml << 'EOF'
[project]
name = "lambda-common-layer"
version = "0.1.0"
requires-python = ">=3.11"
EOF

cat > layers/common/requirements.txt << 'EOF'
pyjwt==2.8.0
cryptography==41.0.7
EOF

# Create layer Python files
mkdir -p layers/common/python/common

cat > layers/common/python/common/utils.py << 'EOF'
import jwt
import json
import os
from typing import Dict, Any, Optional
from datetime import datetime, timezone
from .models import AuthContext

def validate_token(token: str) -> AuthContext:
    """Validate JWT token and return auth context."""
    secret_key = os.environ.get("JWT_SECRET", "your-secret-key")
    
    try:
        payload = jwt.decode(token, secret_key, algorithms=["HS256"])
        return AuthContext(
            user_id=payload["sub"],
            email=payload.get("email"),
            roles=payload.get("roles", []),
            expires_at=payload.get("exp")
        )
    except jwt.ExpiredSignatureError:
        raise jwt.InvalidTokenError("Token has expired")
    except jwt.InvalidTokenError:
        raise

def create_policy(principal_id: str, effect: str, resource: str, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Create IAM policy for API Gateway."""
    policy = {
        "principalId": principal_id,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [{
                "Action": "execute-api:Invoke",
                "Effect": effect,
                "Resource": resource
            }]
        }
    }
    if context:
        policy["context"] = {k: str(v) for k, v in context.items()}
    return policy

def create_response(status_code: int, body: Any, headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
    """Create API Gateway Lambda proxy response."""
    return {
        "statusCode": status_code,
        "headers": headers or {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps(body) if not isinstance(body, str) else body
    }
EOF

cat > layers/common/python/common/models.py << 'EOF'
from dataclasses import dataclass, asdict
from typing import List, Optional
from datetime import datetime

@dataclass
class AuthContext:
    """Authentication context for authorized requests."""
    user_id: str
    email: Optional[str] = None
    roles: List[str] = None
    expires_at: Optional[int] = None
    
    def __post_init__(self):
        if self.roles is None:
            self.roles = []
    
    def to_dict(self) -> dict:
        """Convert to dictionary for API Gateway context."""
        return {
            "userId": self.user_id,
            "email": self.email or "",
            "roles": ",".join(self.roles),
            "expiresAt": str(self.expires_at) if self.expires_at else ""
        }
    
    def is_expired(self) -> bool:
        """Check if the auth context has expired."""
        if not self.expires_at:
            return False
        return datetime.now().timestamp() > self.expires_at

@dataclass
class ResponseModel:
    """Standard API response model."""
    success: bool
    data: Optional[Any] = None
    error: Optional[str] = None
    request_id: Optional[str] = None
    
    def to_dict(self) -> dict:
        """Convert to dictionary."""
        result = {"success": self.success}
        if self.data is not None:
            result["data"] = self.data
        if self.error:
            result["error"] = self.error
        if self.request_id:
            result["requestId"] = self.request_id
        return result
EOF

cat > layers/common/python/common/constants.py << 'EOF'
"""Common constants used across Lambda functions."""

# API Response codes
HTTP_OK = 200
HTTP_CREATED = 201
HTTP_BAD_REQUEST = 400
HTTP_UNAUTHORIZED = 401
HTTP_FORBIDDEN = 403
HTTP_NOT_FOUND = 404
HTTP_INTERNAL_ERROR = 500

# Headers
CONTENT_TYPE_JSON = "application/json"
CONTENT_TYPE_TEXT = "text/plain"

# Error messages
ERROR_UNAUTHORIZED = "Unauthorized"
ERROR_INVALID_TOKEN = "Invalid token"
ERROR_TOKEN_EXPIRED = "Token has expired"
ERROR_INTERNAL = "Internal server error"

# Environment variables
ENV_LOG_LEVEL = "LOG_LEVEL"
ENV_ENVIRONMENT = "ENVIRONMENT"
ENV_JWT_SECRET = "JWT_SECRET"
EOF

# Complete the scripts directory
echo "🛠️  Completing scripts..."

cat > scripts/build_layer.py << 'EOF'
#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
from pathlib import Path

def build_layer():
    """Build the Lambda layer with dependencies."""
    layer_dir = Path("layers/common")
    dist_dir = layer_dir / "dist"
    python_dir = dist_dir / "python"
    
    if dist_dir.exists():
        shutil.rmtree(dist_dir)
    
    python_dir.mkdir(parents=True, exist_ok=True)
    
    src_dir = layer_dir / "python" / "common"
    dst_dir = python_dir / "common"
    shutil.copytree(src_dir, dst_dir)
    
    requirements_file = layer_dir / "requirements.txt"
    if requirements_file.exists():
        subprocess.run([
            sys.executable, "-m", "pip", "install",
            "-r", str(requirements_file),
            "-t", str(python_dir),
            "--platform", "manylinux2014_x86_64",
            "--only-binary", ":all:",
            "--no-compile"
        ], check=True)
    
    print(f"✅ Layer built successfully at {dist_dir}")

if __name__ == "__main__":
    build_layer()
EOF

cat > scripts/package_lambda.py << 'EOF'
#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
from pathlib import Path

def package_lambda(lambda_name: str):
    """Package a Lambda function with its dependencies."""
    lambda_dir = Path(f"lambdas/{lambda_name}")
    dist_dir = lambda_dir / "dist"
    
    if not lambda_dir.exists():
        print(f"❌ Lambda directory not found: {lambda_dir}")
        return False
    
    if dist_dir.exists():
        shutil.rmtree(dist_dir)
    
    dist_dir.mkdir(parents=True, exist_ok=True)
    
    for file in lambda_dir.glob("*.py"):
        if not file.name.startswith("test_"):
            shutil.copy2(file, dist_dir)
    
    requirements_file = lambda_dir / "requirements.txt"
    if requirements_file.exists():
        with open(requirements_file, "r") as f:
            requirements = f.read().strip()
            if requirements and not requirements.startswith("#"):
                subprocess.run([
                    sys.executable, "-m", "pip", "install",
                    "-r", str(requirements_file),
                    "-t", str(dist_dir),
                    "--platform", "manylinux2014_x86_64",
                    "--only-binary", ":all:",
                    "--no-compile"
                ], check=True)
    
    print(f"✅ Lambda {lambda_name} packaged successfully at {dist_dir}")
    return True

def package_all_lambdas():
    """Package all Lambda functions."""
    lambdas_dir = Path("lambdas")
    success = True
    
    for lambda_dir in lambdas_dir.iterdir():
        if lambda_dir.is_dir() and not lambda_dir.name.startswith("_"):
            if not package_lambda(lambda_dir.name):
                success = False
    
    return success

if __name__ == "__main__":
    if len(sys.argv) > 1:
        success = package_lambda(sys.argv[1])
    else:
        success = package_all_lambdas()
    
    sys.exit(0 if success else 1)
EOF

cat > scripts/validate_tags.py << 'EOF'
#!/usr/bin/env python3
import json
import yaml
import sys
from pathlib import Path
from typing import Dict, List, Set

class TagValidator:
    """Validate AWS resource tags against tagging strategy."""
    
    def __init__(self):
        self.mandatory_tags = {
            "Environment", "Project", "Owner", "CostCenter",
            "ManagedBy", "CreatedDate", "DataClassification"
        }
        self.valid_environments = {"dev", "stg", "prd"}
        self.valid_data_classifications = {
            "public", "internal", "confidential", "restricted"
        }
    
    def validate_tags(self, tags: Dict[str, str]) -> List[str]:
        """Validate a set of tags against the tagging strategy."""
        errors = []
        
        missing_tags = self.mandatory_tags - set(tags.keys())
        if missing_tags:
            errors.append(f"Missing mandatory tags: {', '.join(missing_tags)}")
        
        if "Environment" in tags and tags["Environment"] not in self.valid_environments:
            errors.append(f"Invalid Environment tag: {tags['Environment']}")
        
        if "DataClassification" in tags:
            if tags["DataClassification"] not in self.valid_data_classifications:
                errors.append(f"Invalid DataClassification: {tags['DataClassification']}")
        
        if "CreatedDate" in tags:
            try:
                from datetime import datetime
                datetime.strptime(tags["CreatedDate"], "%Y-%m-%d")
            except ValueError:
                errors.append(f"Invalid CreatedDate format: {tags['CreatedDate']}")
        
        return errors

def main():
    """Validate tags in CDK stacks."""
    validator = TagValidator()
    
    test_tags = {
        "Environment": "dev",
        "Project": "lambda-monorepo",
        "Owner": "platform-team",
        "CostCenter": "ENG-001",
        "ManagedBy": "cdk",
        "CreatedDate": "2024-01-15",
        "DataClassification": "internal"
    }
    
    errors = validator.validate_tags(test_tags)
    
    if errors:
        print("❌ Tag validation errors:")
        for error in errors:
            print(f"  - {error}")
        return 1
    else:
        print("✅ All tags are valid")
        return 0

if __name__ == "__main__":
    sys.exit(main())
EOF

chmod +x scripts/*.py

# Create governance files
echo "📋 Creating governance documentation..."

mkdir -p governance/architecture-decisions

cat > governance/README.md << 'EOF'
# Governance Documentation

This directory contains all governance-related documentation for the Lambda monorepo.

## Contents

- `naming-conventions.md` - Resource naming standards
- `tagging-strategy.md` - Tagging requirements and enforcement
- `compliance-checklist.md` - Compliance requirements checklist
- `architecture-decisions/` - Architecture Decision Records (ADRs)

## Enforcement

Governance policies are enforced through:

1. **Automated Validation**: Scripts in `/scripts` validate naming and tagging
2. **CDK Base Stack**: Automatically applies standard tags and naming
3. **CI/CD Pipeline**: Runs governance checks before deployment
4. **AWS Config**: Monitors compliance in deployed resources
EOF

# Create all governance docs (using printf to handle special characters)
printf '%s\n' '# AWS Resource Naming Conventions

## Overview
This document defines the naming standards for all AWS resources in this project.

## General Format
```
{company}-{environment}-{region}-{service}-{resource-type}-{identifier}
```

### Components
- **company**: 3-letter company code (e.g., "acm" for Acme Corp)
- **environment**: dev, stg, prd
- **region**: AWS region code (e.g., use1 for us-east-1)
- **service**: Service/app identifier (e.g., auth, api)
- **resource-type**: AWS resource type abbreviation
- **identifier**: Specific resource identifier

## Resource-Specific Conventions

### Lambda Functions
Pattern: `{company}-{env}-{service}-{function-name}-fn`
Example: `acm-prd-auth-token-validator-fn`

### Lambda Layers
Pattern: `{company}-{env}-common-{layer-name}-layer`
Example: `acm-prd-common-utils-layer`

### API Gateway
Pattern: `{company}-{env}-{service}-api`
Example: `acm-prd-main-api`

### IAM Roles
Pattern: `{company}-{env}-{service}-{resource}-role`
Example: `acm-prd-auth-lambda-role`

## Validation
Use `scripts/validate_naming.py` for automated naming validation.' > governance/naming-conventions.md

# Create config files
echo "⚙️  Creating configuration files..."

cat > config/defaults.yaml << 'EOF'
# Default configuration values
company_code: acm
project_name: lambda-monorepo
owner: platform-team
cost_center: ENG-001
data_classification: internal

# Lambda defaults
lambda:
  runtime: python3.11
  memory_size: 256
  timeout_seconds: 30
  log_retention_days: 30
  reserved_concurrent_executions: null

# API Gateway defaults
api_gateway:
  throttle_rate_limit: 1000
  throttle_burst_limit: 2000
  cache_enabled: false
  cache_ttl_seconds: 300

# Security defaults
security:
  enable_xray_tracing: true
  enable_encryption_at_rest: true
  enable_vpc: false
  allowed_origins:
    - "*"

# Monitoring defaults
monitoring:
  enable_detailed_metrics: true
  alarm_evaluation_periods: 2
  alarm_threshold_percentage: 80
EOF

# Create environment configs
for env in dev stg prod; do
  if [ "$env" = "dev" ]; then
    cat > config/environments/${env}.yaml << 'EOF'
# Development environment configuration
environment: dev
region: us-east-1

# Override defaults for development
lambda:
  memory_size: 256
  timeout_seconds: 30
  log_retention_days: 7

api_gateway:
  throttle_rate_limit: 100
  throttle_burst_limit: 200
  cache_enabled: false

security:
  enable_vpc: false
  allowed_origins:
    - "*"

additional_tags:
  AutoShutdown: "true"
  Purpose: "development"
EOF
  fi
done

# Final message
echo "
✅ Lambda Monorepo setup complete!

🚀 Quick Start:
1. Install dependencies:    make install
2. Configure AWS:          export AWS_PROFILE=your-profile
3. Deploy:                 make deploy

📚 Documentation in governance/ and README.md

Happy coding! 🎉
"
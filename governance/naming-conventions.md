# AWS Resource Naming Conventions

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
Use `scripts/validate_naming.py` for automated naming validation.

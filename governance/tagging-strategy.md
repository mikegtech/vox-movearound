# AWS Resource Tagging Strategy

## Overview

This document defines the tagging strategy for all AWS resources in the Lambda monorepo. Tags are critical for cost allocation, resource management, security, and compliance.

## Mandatory Tags

All AWS resources MUST have the following tags:

| Tag Key | Description | Example Values | Purpose |
|---------|-------------|----------------|---------|
| **Environment** | Deployment environment | `dev`, `stg`, `prd` | Environment isolation, cost tracking |
| **Project** | Project identifier | `lambda-monorepo`, `vox-platform` | Resource grouping, cost allocation |
| **Owner** | Team or individual owner | `platform-team`, `john.doe@company.com` | Accountability, contact for issues |
| **CostCenter** | Financial cost center | `ENG-001`, `PLATFORM-100` | Financial reporting, chargebacks |
| **ManagedBy** | IaC tool managing resource | `cdk`, `terraform`, `manual` | Change control, drift prevention |
| **CreatedDate** | Resource creation date | `2024-07-26` | Lifecycle management, auditing |
| **DataClassification** | Data sensitivity level | `public`, `internal`, `confidential`, `restricted` | Security controls, compliance |

### Tag Definitions

#### Environment
- **Purpose**: Identifies deployment environment
- **Values**: 
  - `dev` - Development environment
  - `stg` - Staging/QA environment
  - `prd` - Production environment
- **Usage**: Cost allocation, IAM policies, automation rules

#### Project
- **Purpose**: Groups resources by project or application
- **Format**: Lowercase, hyphenated
- **Examples**: `user-service`, `payment-processor`, `data-pipeline`

#### Owner
- **Purpose**: Identifies responsible team or individual
- **Format**: Team name or email address
- **Examples**: `platform-team`, `data-engineering`, `alice.smith@company.com`

#### CostCenter
- **Purpose**: Maps resources to financial cost centers
- **Format**: Department code + number
- **Examples**: `ENG-001`, `MARKETING-002`, `OPS-003`

#### ManagedBy
- **Purpose**: Indicates how resource is managed
- **Values**:
  - `cdk` - AWS CDK managed
  - `terraform` - Terraform managed
  - `cloudformation` - CloudFormation managed
  - `manual` - Manually created (discouraged)

#### CreatedDate
- **Purpose**: Tracks when resource was created
- **Format**: ISO 8601 date (YYYY-MM-DD)
- **Example**: `2024-07-26`

#### DataClassification
- **Purpose**: Indicates data sensitivity for security controls
- **Values**:
  - `public` - Public information
  - `internal` - Internal use only
  - `confidential` - Confidential business data
  - `restricted` - Highly sensitive (PII, PCI, etc.)

## Optional Tags

These tags are recommended for specific use cases:

| Tag Key | Description | Example Values | When to Use |
|---------|-------------|----------------|-------------|
| **Application** | Specific application name | `auth-service`, `user-api` | Multi-app environments |
| **Version** | Application version | `v1.2.3`, `v2.0.0-beta` | Version tracking |
| **Schedule** | Operating schedule | `office-hours`, `24x7`, `weekdays` | Cost optimization |
| **Backup** | Backup requirements | `daily`, `weekly`, `none` | Backup automation |
| **Compliance** | Compliance frameworks | `pci`, `hipaa`, `sox`, `gdpr` | Compliance tracking |
| **ExpiryDate** | Resource expiration | `2024-12-31` | Temporary resources |
| **GitCommit** | Git commit hash | `a1b2c3d4` | Deployment tracking |

## Environment-Specific Tags

### Development Environment
```yaml
Environment: dev
AutoShutdown: "true"              # Enable automated shutdown
Purpose: "development"             # Resource purpose
DeleteAfter: "30-days"            # Automatic cleanup
```

### Staging Environment
```yaml
Environment: stg
Purpose: "testing"
PerformanceTesting: "enabled"
DataRetention: "7-days"
```

### Production Environment
```yaml
Environment: prd
SLA: "99.99"                      # Service level agreement
CriticalityLevel: "critical"      # Business criticality
DisasterRecovery: "active-passive" # DR strategy
BackupRetention: "365-days"       # Backup retention period
MonitoringLevel: "enhanced"       # Enhanced monitoring
```

## Resource-Specific Tags

### Lambda Functions
```yaml
# Required
Runtime: "python3.11"
HandlerType: "api"                # api, authorizer, event, scheduled
MemorySize: "256"
Timeout: "30"

# Optional
LayerDependency: "arn:aws:lambda:region:account:layer:name:version"
VPCEnabled: "true"
ReservedConcurrency: "100"
```

### API Gateway
```yaml
# Required
APIType: "REST"                   # REST, HTTP, WebSocket
Stage: "v1"
AuthType: "cognito"              # cognito, iam, api-key, custom

# Optional
RateLimitBurst: "5000"
RateLimitRate: "2000"
CachingEnabled: "true"
```

### S3 Buckets
```yaml
# Required
BucketPurpose: "logs"            # logs, backups, static-assets, data
EncryptionType: "SSE-S3"         # SSE-S3, SSE-KMS, SSE-C
PublicAccess: "blocked"          # blocked, read-only, read-write

# Optional
LifecycleEnabled: "true"
VersioningEnabled: "true"
ReplicationEnabled: "false"
```

### RDS/DynamoDB
```yaml
# Required
DatabaseEngine: "postgres"        # postgres, mysql, dynamodb
BackupEnabled: "true"
EncryptionEnabled: "true"

# Optional
MultiAZ: "true"
ReadReplicas: "2"
BackupWindow: "03:00-04:00"
MaintenanceWindow: "sun:04:00-sun:05:00"
```

## Tag Implementation

### CDK Implementation (BaseStack)
```python
from aws_cdk import Tags, Stack
from datetime import datetime

class BaseStack(Stack):
    def _apply_standard_tags(self):
        """Apply mandatory tags to all resources."""
        Tags.of(self).add("Environment", self.environment)
        Tags.of(self).add("Project", self.config["project_name"])
        Tags.of(self).add("Owner", self.config["owner"])
        Tags.of(self).add("CostCenter", self.config["cost_center"])
        Tags.of(self).add("ManagedBy", "cdk")
        Tags.of(self).add("CreatedDate", datetime.now().strftime("%Y-%m-%d"))
        Tags.of(self).add("DataClassification", self.config.get("data_classification", "internal"))
```

### Manual Tagging Example
```bash
aws lambda tag-resource \
  --resource arn:aws:lambda:region:account:function:name \
  --tags Environment=prd,Owner=platform-team,CostCenter=ENG-001
```

## Tag Policies

### AWS Organizations Tag Policies
```json
{
  "tags": {
    "Environment": {
      "tag_key": "Environment",
      "enforced_for": ["lambda:function", "apigateway:restapis"],
      "values": ["dev", "stg", "prd"]
    },
    "CostCenter": {
      "tag_key": "CostCenter",
      "enforced_for": ["*"],
      "values": ["@@assign"]
    }
  }
}
```

### Enforcement Mechanisms

1. **Preventive Controls**
   - AWS Organizations Tag Policies
   - IAM policies denying resource creation without tags
   - CDK/Terraform validation

2. **Detective Controls**
   - AWS Config rules for tag compliance
   - Custom Lambda functions for validation
   - Regular compliance reports

3. **Corrective Controls**
   - Auto-tagging Lambda functions
   - Scheduled remediation jobs
   - Notification of non-compliant resources

## Tag Governance

### Quarterly Tag Audit
1. Run tag compliance report
2. Identify untagged resources
3. Notify resource owners
4. Apply missing tags
5. Update tag policies if needed

### Tag Lifecycle
1. **Creation**: Applied automatically via IaC
2. **Updates**: Through IaC changes only
3. **Validation**: Daily automated checks
4. **Reporting**: Weekly compliance reports
5. **Cleanup**: Remove tags from deleted resources

## Cost Allocation

### Activating Cost Allocation Tags
1. AWS Console → Billing → Cost Allocation Tags
2. Activate all mandatory tags
3. Wait 24 hours for data population

### Cost Reports by Tag
- **By Environment**: Compare dev/stg/prd costs
- **By Team**: Owner tag for team chargebacks
- **By Project**: Project-level cost tracking
- **By Cost Center**: Financial reporting

## Best Practices

1. **Consistency**: Always use lowercase for tag values
2. **Automation**: Never manually tag IaC-managed resources
3. **Validation**: Run tag validation before deployment
4. **Documentation**: Document any custom tags in team wiki
5. **Review**: Regularly review and update tag strategy

## Tag Limits

- Maximum 50 tags per resource
- Tag key: Maximum 128 characters
- Tag value: Maximum 256 characters
- Tag keys and values are case-sensitive

## Validation Script

Use `scripts/validate_tags.py` to validate tags:

```bash
# Validate all resources
python scripts/validate_tags.py

# Validate specific stack
python scripts/validate_tags.py --stack-name my-stack

# Generate compliance report
python scripts/validate_tags.py --report
```

## Non-Compliance Process

1. **Detection**: AWS Config rule triggers
2. **Notification**: Email to resource owner
3. **Grace Period**: 7 days to fix
4. **Escalation**: Manager notification
5. **Remediation**: Auto-tagging or resource termination

## Future Enhancements

- [ ] Automated tag inheritance
- [ ] Machine learning for tag suggestions
- [ ] Real-time tag compliance dashboard
- [ ] Integration with ServiceNow for tag management
- [ ] Tag-based access control (ABAC)

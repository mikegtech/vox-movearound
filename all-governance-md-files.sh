#!/bin/bash

# Script to create all governance markdown files

echo "📝 Creating all governance markdown files..."

# Create governance/tagging-strategy.md
cat > governance/tagging-strategy.md << 'EOF'
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
EOF

# Create governance/compliance-checklist.md
cat > governance/compliance-checklist.md << 'EOF'
# Compliance Checklist

This checklist ensures all Lambda monorepo deployments meet security, operational, regulatory, and cost compliance requirements.

## How to Use This Checklist

1. **Development Phase**: Reference during development
2. **Pre-Deployment**: Complete all items before production
3. **Regular Audits**: Review monthly/quarterly
4. **Evidence Collection**: Document completion for auditors

---

## Security Compliance

### Data Protection
- [ ] **All data at rest is encrypted using AWS KMS**
  - S3 buckets use SSE-KMS or SSE-S3
  - RDS instances have encryption enabled
  - DynamoDB tables use encryption at rest
  - EBS volumes are encrypted
  - *Validation*: Run `aws s3api get-bucket-encryption --bucket BUCKET_NAME`

- [ ] **All data in transit uses TLS 1.2 or higher**
  - API Gateway enforces TLS 1.2 minimum
  - ALB/NLB listeners use TLS 1.2+ policies
  - Lambda functions use HTTPS for external calls
  - *Validation*: SSL Labs scan, check ALB security policies

- [ ] **Sensitive data is classified and tagged appropriately**
  - DataClassification tag applied to all resources
  - Resources handling PII tagged as "restricted"
  - Encryption requirements match classification
  - *Validation*: Tag compliance report

- [ ] **PII data is masked in logs**
  - CloudWatch Logs don't contain unmasked PII
  - Application logs use data masking
  - Error messages don't expose sensitive data
  - *Validation*: Log analysis with PII detection tools

### Access Control
- [ ] **IAM roles follow principle of least privilege**
  - Each Lambda has its own execution role
  - No wildcard (*) permissions unless justified
  - Roles scoped to specific resources
  - Regular access reviews conducted
  - *Validation*: IAM Access Analyzer findings

- [ ] **No hardcoded credentials in code**
  - All credentials in Secrets Manager or Parameter Store
  - Environment variables don't contain secrets
  - Git-secrets scan passes
  - Code reviews check for credentials
  - *Validation*: Run `git secrets --scan`

- [ ] **Secrets are stored in AWS Secrets Manager**
  - API keys in Secrets Manager
  - Database passwords auto-rotated
  - Encryption keys in KMS
  - Access limited by IAM
  - *Validation*: List all secrets, verify rotation

- [ ] **MFA is required for production access**
  - AWS Console requires MFA
  - CLI access requires MFA for production
  - Break-glass procedures documented
  - *Validation*: IAM credential report

### Network Security
- [ ] **Lambda functions in VPC for production**
  - Production Lambdas in private subnets
  - NAT Gateway for internet access
  - VPC endpoints for AWS services
  - Network ACLs configured
  - *Validation*: Lambda configuration audit

- [ ] **Security groups follow least privilege**
  - Inbound rules limited to required ports
  - Outbound rules explicitly defined
  - No 0.0.0.0/0 inbound rules
  - Regular security group audits
  - *Validation*: AWS Config security group rules

- [ ] **NACLs configured for additional protection**
  - Subnet-level security rules
  - Deny rules for known bad IPs
  - Stateless rules documented
  - *Validation*: VPC network ACL review

- [ ] **Private subnets used for compute resources**
  - Lambda functions in private subnets
  - RDS in private subnets
  - Public subnets only for load balancers
  - *Validation*: Subnet route table review

---

## Operational Compliance

### Monitoring & Logging
- [ ] **CloudWatch Logs retention configured**
  - Development: 7 days
  - Staging: 30 days
  - Production: 365 days minimum
  - Costs monitored for long retention
  - *Validation*: Check log group retention settings

- [ ] **X-Ray tracing enabled for all functions**
  - All Lambda functions have tracing enabled
  - Service map shows all dependencies
  - Performance baselines established
  - *Validation*: X-Ray service map completeness

- [ ] **CloudWatch alarms for key metrics**
  - Lambda errors > threshold
  - Lambda duration > threshold
  - API Gateway 4xx/5xx rates
  - DLQ messages
  - *Validation*: List all alarms per function

- [ ] **Log aggregation to central location**
  - Logs shipped to central account
  - Log analytics tools configured
  - Retention policies applied
  - Search capabilities tested
  - *Validation*: Query logs across accounts

### Backup & Recovery
- [ ] **Backup strategy documented**
  - What to backup identified
  - Backup frequency defined
  - Backup retention periods set
  - Backup testing schedule
  - *Validation*: Backup strategy document

- [ ] **RTO/RPO defined for each service**
  - Recovery Time Objective documented
  - Recovery Point Objective documented
  - Aligned with business requirements
  - Tested and validated
  - *Validation*: RTO/RPO documentation

- [ ] **Disaster recovery plan tested**
  - DR procedures documented
  - Quarterly DR drills conducted
  - Results documented
  - Improvements implemented
  - *Validation*: DR test reports

- [ ] **Data retention policies implemented**
  - Legal requirements identified
  - Automated deletion configured
  - Audit trail maintained
  - *Validation*: Lifecycle policies active

### Change Management
- [ ] **All changes go through CI/CD pipeline**
  - No manual production deployments
  - Pipeline stages documented
  - Approvals required for production
  - Rollback procedures tested
  - *Validation*: Deployment history audit

- [ ] **Infrastructure changes reviewed via PR**
  - All IaC changes in Git
  - PR template includes checklist
  - Two approvals for production changes
  - Security review for sensitive changes
  - *Validation*: Git history and PR approvals

- [ ] **Rollback procedures documented**
  - Step-by-step rollback guide
  - Rollback tested quarterly
  - Time to rollback measured
  - Stakeholder communication plan
  - *Validation*: Rollback documentation

- [ ] **Change approval process followed**
  - Change Advisory Board (CAB) for major changes
  - Emergency change procedures
  - Change calendar maintained
  - Post-implementation reviews
  - *Validation*: Change tickets and approvals

---

## Regulatory Compliance

### GDPR (if applicable)
- [ ] **Data processing agreements in place**
  - DPAs with all third-party processors
  - Sub-processor list maintained
  - Annual DPA review
  - *Validation*: DPA registry

- [ ] **Right to erasure implemented**
  - Data deletion procedures documented
  - Deletion requests tracked
  - Backups included in deletion
  - Deletion verified
  - *Validation*: Deletion request logs

- [ ] **Data portability supported**
  - Export functionality available
  - Standard formats used
  - Reasonable timeframe (30 days)
  - *Validation*: Test data export

- [ ] **Privacy by design principles followed**
  - Data minimization implemented
  - Purpose limitation enforced
  - Privacy impact assessments
  - *Validation*: PIA documentation

### SOC 2 (if applicable)
- [ ] **Access controls documented**
  - Access matrix maintained
  - Onboarding/offboarding procedures
  - Quarterly access reviews
  - Privileged access management
  - *Validation*: Access control documentation

- [ ] **Change management process documented**
  - Change procedures written
  - Approval workflows defined
  - Testing requirements
  - Documentation requirements
  - *Validation*: Change management policy

- [ ] **Incident response plan in place**
  - Incident classification defined
  - Response team identified
  - Communication plan ready
  - Lessons learned process
  - *Validation*: Incident response tests

- [ ] **Regular security assessments**
  - Annual penetration testing
  - Quarterly vulnerability scans
  - Code security reviews
  - Third-party audits
  - *Validation*: Assessment reports

### HIPAA (if applicable)
- [ ] **PHI encryption at rest and in transit**
- [ ] **Access controls and audit logs**
- [ ] **Business Associate Agreements (BAAs)**
- [ ] **Risk assessments conducted**

### PCI DSS (if applicable)
- [ ] **Network segmentation implemented**
- [ ] **Cardholder data encrypted**
- [ ] **Access control measures**
- [ ] **Regular security testing**

---

## Cost Compliance

### Resource Optimization
- [ ] **Unused resources identified and removed**
  - Weekly scan for unused resources
  - Automated cleanup for dev/staging
  - Approval process for deletion
  - Cost savings tracked
  - *Validation*: Resource utilization reports

- [ ] **Right-sizing analysis completed**
  - Lambda memory optimization
  - Database instance sizing
  - Storage optimization
  - Performance vs. cost balanced
  - *Validation*: AWS Compute Optimizer recommendations

- [ ] **Reserved capacity evaluated**
  - RI/Savings Plans analysis
  - Commitment vs. usage tracked
  - Regular review cycle
  - *Validation*: RI utilization reports

- [ ] **Cost allocation tags applied**
  - All mandatory tags present
  - Cost center tags accurate
  - Project tags consistent
  - *Validation*: Tag compliance report

### Budget Controls
- [ ] **Budget alerts configured**
  - Monthly budget set
  - 80% and 100% alerts
  - Forecast alerts enabled
  - Alert recipients defined
  - *Validation*: AWS Budgets configuration

- [ ] **Cost anomaly detection enabled**
  - AWS Cost Anomaly Detection active
  - Custom monitors configured
  - Alert thresholds appropriate
  - *Validation*: Anomaly detection settings

- [ ] **Regular cost reviews scheduled**
  - Monthly cost review meetings
  - Quarterly optimization reviews
  - Annual budget planning
  - Cost trends analyzed
  - *Validation*: Meeting minutes

- [ ] **Tagging strategy enforced**
  - Tag policies active
  - Non-compliant resources blocked
  - Regular tag audits
  - *Validation*: Tag policy compliance

---

## Validation and Reporting

### Automated Compliance Checks
```bash
# Run all compliance checks
make compliance-report

# Security compliance only
make security-compliance

# Cost compliance only
make cost-compliance
```

### Manual Verification Steps
1. Review AWS Security Hub findings
2. Check AWS Config compliance dashboard
3. Analyze Cost Explorer reports
4. Review CloudTrail logs
5. Verify backup restoration

### Compliance Metrics
- **Target**: 100% compliance for production
- **Acceptable**: 95% compliance for staging
- **Minimum**: 90% compliance for development

### Non-Compliance Process
1. **Identify**: Automated scan detects issue
2. **Notify**: Team notified within 1 hour
3. **Assess**: Risk assessment within 4 hours
4. **Fix**: Resolution within SLA
5. **Verify**: Compliance confirmed
6. **Document**: Root cause analysis

---

## Compliance Calendar

### Daily
- [ ] Security alert review
- [ ] Cost anomaly review
- [ ] Failed deployment investigation

### Weekly
- [ ] Tag compliance audit
- [ ] Unused resource cleanup
- [ ] Access review for changes

### Monthly
- [ ] Full compliance checklist review
- [ ] Cost optimization meeting
- [ ] Security patches applied
- [ ] Backup restoration test

### Quarterly
- [ ] DR drill
- [ ] Security assessment
- [ ] Access certification
- [ ] Policy review and update

### Annually
- [ ] Penetration testing
- [ ] Compliance training
- [ ] Policy major revision
- [ ] Third-party audit

---

## Evidence Collection

For audits, maintain evidence of:
1. Completed checklists with dates
2. Validation command outputs
3. Screenshots of dashboards
4. Approval emails/tickets
5. Test results and reports
6. Meeting minutes
7. Training records

Store evidence in:
- S3 bucket with versioning
- Retention per compliance requirements
- Access logging enabled
- Encryption at rest
EOF

# Create governance/architecture-decisions/001-monorepo-structure.md
mkdir -p governance/architecture-decisions
cat > governance/architecture-decisions/001-monorepo-structure.md << 'EOF'
# ADR-001: Monorepo Structure for Lambda Functions

## Status

Accepted

## Context

Our organization needs to manage multiple AWS Lambda functions that share common code, require consistent deployment patterns, and must maintain high development velocity while ensuring quality and compliance.

### Requirements
- Multiple Lambda functions with shared utilities
- Consistent deployment and testing patterns
- Cost-effective dependency management
- Easy onboarding for new developers
- Support for local development and testing
- Compliance with organizational governance

### Constraints
- Team has varying levels of AWS experience
- Need to minimize cold start times
- Budget constraints on AWS resources
- Must support multiple environments (dev, staging, prod)
- Regulatory requirements for code auditing

### Options Considered

1. **Separate Repositories per Lambda**
   - Pros: Independent deployments, clear ownership
   - Cons: Code duplication, inconsistent patterns, difficult dependency management

2. **Monorepo with Shared Libraries via npm**
   - Pros: Code reuse, consistent patterns
   - Cons: Complex dependency management, versioning challenges

3. **Monorepo with Lambda Layers**
   - Pros: Code reuse, reduced package size, consistent patterns
   - Cons: Layer version management, 5 layer limit per function

4. **Multi-repo with Git Submodules**
   - Pros: Some code reuse, independent repos
   - Cons: Complex Git workflows, submodule management overhead

## Decision

We will use a **Monorepo structure with Lambda Layers** for shared code.

### Architecture
```
lambda-monorepo/
├── infrastructure/      # CDK code for all resources
├── lambdas/            # Individual Lambda functions
├── layers/             # Shared Lambda layers
├── governance/         # Standards and policies
└── scripts/           # Build and deployment tools
```

### Key Decisions

1. **Package Management**: Use `uvx` for Python dependency management
   - Faster than pip
   - Better dependency resolution
   - Lock file support

2. **Infrastructure as Code**: AWS CDK with TypeScript
   - Type safety for infrastructure
   - Better than raw CloudFormation
   - Good AWS service coverage

3. **Shared Code**: Lambda Layers
   - Common utilities in layers
   - Reduces deployment package size
   - Improves cold start performance

4. **Testing Strategy**: Pytest with coverage requirements
   - Unit tests for each Lambda
   - Integration tests in `/tests`
   - Minimum 80% coverage

5. **Deployment Strategy**: Single CDK app with multiple stacks
   - Layer stack deployed first
   - Lambda stack depends on layer stack
   - Environment-specific configurations

## Consequences

### Positive Consequences

1. **Code Reuse**: Shared utilities via layers eliminate duplication
2. **Consistency**: All functions follow same patterns
3. **Cost Optimization**: Smaller deployment packages, shared dependencies
4. **Developer Experience**: Single repo to clone, consistent tooling
5. **Governance**: Centralized standards enforcement
6. **Testing**: Shared testing utilities and patterns
7. **Deployment**: Atomic deployments of related functions

### Negative Consequences

1. **Coupling**: All functions deployed together (initially)
2. **Repository Size**: Can grow large over time
3. **Build Complexity**: More complex build process
4. **Layer Limits**: Maximum 5 layers per Lambda
5. **Version Management**: Layer versions need careful management
6. **Access Control**: Everyone sees all code

### Mitigations

1. **Coupling Mitigation**:
   - Use feature flags for gradual rollouts
   - Implement CDK stack separation for independent deployments
   - Create deployment groups for related functions

2. **Repository Size Mitigation**:
   - Regular cleanup of old code
   - Git LFS for large files
   - Archived functions moved to cold storage

3. **Build Complexity Mitigation**:
   - Comprehensive build scripts
   - Clear documentation
   - Automated build pipeline

4. **Layer Limits Mitigation**:
   - Consolidate related utilities
   - Monitor layer usage
   - Plan for layer splitting strategy

5. **Version Management Mitigation**:
   - Semantic versioning for layers
   - Automated compatibility testing
   - Version pinning in functions

6. **Access Control Mitigation**:
   - Use CODEOWNERS file
   - Branch protection rules
   - Consider future split if needed

## Implementation Plan

### Phase 1: Foundation (Week 1-2)
- Set up repository structure
- Create base CDK stacks
- Implement governance documents
- Create first Lambda with layer

### Phase 2: Migration (Week 3-4)
- Migrate existing Lambdas
- Extract common code to layers
- Set up CI/CD pipeline
- Implement testing framework

### Phase 3: Optimization (Week 5-6)
- Performance tuning
- Cost optimization
- Monitoring setup
- Documentation completion

## Success Metrics

1. **Development Velocity**: 50% reduction in new Lambda creation time
2. **Code Reuse**: 70% of functions use shared layers
3. **Deployment Time**: < 5 minutes for full deployment
4. **Test Coverage**: > 80% across all functions
5. **Cost Reduction**: 30% reduction in Lambda storage costs

## Review Date

This decision will be reviewed in 6 months (January 2025) to assess:
- Developer satisfaction
- Deployment frequency and success rate
- Cost optimization achieved
- Technical debt accumulated
- Need for adjustments

## References

- [AWS Lambda Layers Documentation](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html)
- [CDK Best Practices](https://docs.aws.amazon.com/cdk/latest/guide/best-practices.html)
- [Monorepo vs Polyrepo](https://github.com/joelparkerhenderson/monorepo_vs_polyrepo)
- [Python Packaging Best Practices](https://packaging.python.org/en/latest/guides/)

## Appendix: Decision Matrix

| Criteria | Separate Repos | Monorepo + npm | Monorepo + Layers | Multi-repo + Submodules |
|----------|---------------|----------------|-------------------|-------------------------|
| Code Reuse | ❌ | ✅ | ✅ | 🟡 |
| Deployment Speed | ✅ | 🟡 | ✅ | 🟡 |
| Complexity | ✅ | 🟡 | 🟡 | ❌ |
| Cost | ❌ | 🟡 | ✅ | 🟡 |
| Governance | ❌ | ✅ | ✅ | 🟡 |
| **Total Score** | 2/5 | 3.5/5 | **4.5/5** | 2.5/5 |

Legend: ✅ Good (1 point) | 🟡 Acceptable (0.5 points) | ❌ Poor (0 points)
EOF

echo "✅ All governance markdown files created successfully!"
echo ""
echo "📁 Created files:"
echo "  - governance/tagging-strategy.md"
echo "  - governance/compliance-checklist.md"
echo "  - governance/architecture-decisions/001-monorepo-structure.md"
echo ""
echo "📋 You already have:"
echo "  - governance/README.md"
echo "  - governance/naming-conventions.md"
echo ""
echo "🎯 Next steps:"
echo "  1. Review and customize the files for your organization"
echo "  2. Update company-specific values (company code, cost centers, etc.)"
echo "  3. Add any additional compliance requirements"
echo "  4. Share with your team for feedback"

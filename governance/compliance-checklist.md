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

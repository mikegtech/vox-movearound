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

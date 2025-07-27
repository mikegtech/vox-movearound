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

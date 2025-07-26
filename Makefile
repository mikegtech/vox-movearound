.PHONY: install test lint format deploy clean validate-naming validate-tags governance-check compliance-report pre-deploy

# Install all dependencies
install:
	uvx pip install -e .
	cd infrastructure && uvx pip install -r requirements.txt
	cd lambdas/authorizer && uvx pip install -r requirements.txt
	cd layers/common && uvx pip install -r requirements.txt

# Run tests
test:
	uvx pytest tests/ -v
	cd lambdas/authorizer && uvx pytest tests/ -v

# Lint code
lint:
	uvx ruff check .
	uvx mypy .

# Format code
format:
	uvx black .
	uvx ruff check . --fix

# Build Lambda layer
build-layer:
	python scripts/build_layer.py

# Package Lambda functions
package-lambdas:
	python scripts/package_lambda.py

# Deploy infrastructure
deploy: build-layer package-lambdas
	cd infrastructure && uvx cdk deploy --all

# Clean build artifacts
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf dist/ build/ .aws-sam/

# Validate naming conventions
validate-naming:
	python scripts/validate_naming.py

# Validate tagging compliance
validate-tags:
	python scripts/validate_tags.py

# Run all governance checks
governance-check: validate-naming validate-tags
	@echo "All governance checks passed"

# Generate compliance report
compliance-report:
	python scripts/generate_compliance_report.py

# Pre-deployment validation
pre-deploy: lint test governance-check
	@echo "Pre-deployment validation complete"

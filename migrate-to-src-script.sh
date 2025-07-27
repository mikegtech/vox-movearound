#!/bin/bash

# Migration script to convert Lambda monorepo to use src directory structure

echo "🔄 Migrating Lambda Monorepo to src directory structure..."

# Function to migrate a Lambda function
migrate_lambda() {
    local lambda_name=$1
    echo "  📦 Migrating ${lambda_name}..."
    
    # Create src directory structure
    mkdir -p "lambdas/${lambda_name}/src/${lambda_name}"
    
    # Move handler.py if it exists
    if [ -f "lambdas/${lambda_name}/handler.py" ]; then
        mv "lambdas/${lambda_name}/handler.py" "lambdas/${lambda_name}/src/${lambda_name}/"
    fi
    
    # Create __init__.py
    touch "lambdas/${lambda_name}/src/${lambda_name}/__init__.py"
    
    # Create setup.py
    cat > "lambdas/${lambda_name}/setup.py" << EOF
from setuptools import setup, find_packages

setup(
    name="lambda-${lambda_name}",
    version="0.1.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.12",
)
EOF

    # Update pyproject.toml
    cat > "lambdas/${lambda_name}/pyproject.toml" << EOF
[project]
name = "lambda-${lambda_name}"
version = "0.1.0"
requires-python = ">=3.12"

[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
where = ["src"]

[tool.setuptools.package-data]
${lambda_name} = ["py.typed"]
EOF
}

# Migrate Lambda functions
echo "🐍 Migrating Lambda functions..."
for lambda_dir in lambdas/*/; do
    if [ -d "$lambda_dir" ]; then
        lambda_name=$(basename "$lambda_dir")
        if [ "$lambda_name" != "__pycache__" ]; then
            migrate_lambda "$lambda_name"
        fi
    fi
done

# Migrate common layer
echo "📚 Migrating common layer..."
if [ -d "layers/common/python/common" ]; then
    mkdir -p "layers/common/src"
    mv "layers/common/python/common" "layers/common/src/"
    rm -rf "layers/common/python"
fi

# Create layer setup.py
cat > "layers/common/setup.py" << 'EOF'
from setuptools import setup, find_packages

setup(
    name="lambda-common-layer",
    version="0.1.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.11",
)
EOF

# Update layer pyproject.toml
cat > "layers/common/pyproject.toml" << 'EOF'
[project]
name = "lambda-common-layer"
version = "0.1.0"
requires-python = ">=3.11"

[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
where = ["src"]

[tool.setuptools.package-data]
common = ["py.typed"]
EOF

# Update infrastructure CDK code
echo "🏗️  Updating CDK handler references..."

# Create a backup of lambda_stack.py
cp infrastructure/stacks/lambda_stack.py infrastructure/stacks/lambda_stack.py.bak

# Update handler paths in lambda_stack.py
sed -i 's/handler="handler.lambda_handler"/handler="authorizer.handler.lambda_handler"/g' infrastructure/stacks/lambda_stack.py
sed -i 's/handler="handler.lambda_handler"/handler="api_handler.handler.lambda_handler"/g' infrastructure/stacks/lambda_stack.py

# Update pytest.ini
echo "🧪 Creating pytest configuration..."
cat > pytest.ini << 'EOF'
[pytest]
testpaths = tests lambdas/*/tests layers/*/tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --tb=short --cov=src --cov=lambdas/*/src --cov=layers/*/src
pythonpath = .
EOF

# Update root pyproject.toml
echo "📝 Updating root pyproject.toml..."
cat > pyproject.toml << 'EOF'
[project]
name = "lambda-monorepo"
version = "0.1.0"
description = "Monorepo for AWS Lambda functions"
requires-python = ">=3.12"

[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
where = ["src"]

[tool.uv]
dev-dependencies = [
    "pytest>=7.4.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.5.0",
]

[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W"]
src = ["src", "lambdas/*/src", "layers/*/src"]

[tool.black]
line-length = 88

[tool.mypy]
python_version = "3.12"
warn_return_any = true
warn_unused_configs = true
namespace_packages = true
explicit_package_bases = true
mypy_path = "src,lambdas/*/src,layers/*/src"
EOF

# Create .editorconfig for consistent formatting
echo "📐 Creating .editorconfig..."
cat > .editorconfig << 'EOF'
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{yml,yaml}]
indent_size = 2

[Makefile]
indent_style = tab

[*.md]
trim_trailing_whitespace = false
EOF

# Update scripts to handle new structure
echo "🛠️  Updating build scripts..."

# The build scripts are already updated in the previous artifact
# Just copy them from there or use the restructure script

# Create a verification script
echo "✅ Creating verification script..."
cat > verify_migration.py << 'EOF'
#!/usr/bin/env python3
"""Verify the migration to src structure was successful."""
import sys
from pathlib import Path

def verify_structure():
    """Verify the new structure is correct."""
    issues = []
    
    # Check Lambda functions
    for lambda_path in Path("lambdas").glob("*/"):
        if lambda_path.is_dir() and lambda_path.name != "__pycache__":
            src_dir = lambda_path / "src" / lambda_path.name
            handler_file = src_dir / "handler.py"
            init_file = src_dir / "__init__.py"
            
            if not src_dir.exists():
                issues.append(f"Missing src directory: {src_dir}")
            if not handler_file.exists():
                issues.append(f"Missing handler file: {handler_file}")
            if not init_file.exists():
                issues.append(f"Missing __init__.py: {init_file}")
    
    # Check layer
    layer_src = Path("layers/common/src/common")
    if not layer_src.exists():
        issues.append(f"Missing layer src directory: {layer_src}")
    
    # Check for required files in layer
    for module in ["__init__.py", "utils.py", "models.py", "constants.py"]:
        module_path = layer_src / module
        if not module_path.exists():
            issues.append(f"Missing layer module: {module_path}")
    
    # Report results
    if issues:
        print("❌ Migration issues found:")
        for issue in issues:
            print(f"  - {issue}")
        return False
    else:
        print("✅ Migration successful! All files in correct locations.")
        return True

if __name__ == "__main__":
    sys.exit(0 if verify_structure() else 1)
EOF

chmod +x verify_migration.py

# Run verification
echo ""
echo "🔍 Verifying migration..."
python verify_migration.py

echo ""
echo "📋 Migration complete! Next steps:"
echo "1. Review the changes (especially infrastructure/stacks/lambda_stack.py)"
echo "2. Run 'make clean' to remove old build artifacts"
echo "3. Run 'make install' to install with new structure"
echo "4. Run 'make test' to verify everything works"
echo "5. Run 'make deploy' when ready"
echo ""
echo "💡 Benefits of new structure:"
echo "  - Cleaner imports (e.g., 'from authorizer.handler import lambda_handler')"
echo "  - Better package isolation"
echo "  - Improved IDE support"
echo "  - Follows Python best practices"

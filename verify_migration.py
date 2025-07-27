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

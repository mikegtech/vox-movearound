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

#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
from pathlib import Path

def build_layer():
    """Build the Lambda layer with dependencies."""
    layer_dir = Path("layers/common")
    dist_dir = layer_dir / "dist"
    python_dir = dist_dir / "python"
    
    if dist_dir.exists():
        shutil.rmtree(dist_dir)
    
    python_dir.mkdir(parents=True, exist_ok=True)
    
    src_dir = layer_dir / "python" / "common"
    dst_dir = python_dir / "common"
    shutil.copytree(src_dir, dst_dir)
    
    requirements_file = layer_dir / "requirements.txt"
    if requirements_file.exists():
        subprocess.run([
            sys.executable, "-m", "pip", "install",
            "-r", str(requirements_file),
            "-t", str(python_dir),
            "--platform", "manylinux2014_x86_64",
            "--only-binary", ":all:",
            "--no-compile"
        ], check=True)
    
    print(f"✅ Layer built successfully at {dist_dir}")

if __name__ == "__main__":
    build_layer()

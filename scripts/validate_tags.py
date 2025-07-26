#!/usr/bin/env python3
import json
import yaml
import sys
from pathlib import Path
from typing import Dict, List, Set

class TagValidator:
    """Validate AWS resource tags against tagging strategy."""
    
    def __init__(self):
        self.mandatory_tags = {
            "Environment", "Project", "Owner", "CostCenter",
            "ManagedBy", "CreatedDate", "DataClassification"
        }
        self.valid_environments = {"dev", "stg", "prd"}
        self.valid_data_classifications = {
            "public", "internal", "confidential", "restricted"
        }
    
    def validate_tags(self, tags: Dict[str, str]) -> List[str]:
        """Validate a set of tags against the tagging strategy."""
        errors = []
        
        missing_tags = self.mandatory_tags - set(tags.keys())
        if missing_tags:
            errors.append(f"Missing mandatory tags: {', '.join(missing_tags)}")
        
        if "Environment" in tags and tags["Environment"] not in self.valid_environments:
            errors.append(f"Invalid Environment tag: {tags['Environment']}")
        
        if "DataClassification" in tags:
            if tags["DataClassification"] not in self.valid_data_classifications:
                errors.append(f"Invalid DataClassification: {tags['DataClassification']}")
        
        if "CreatedDate" in tags:
            try:
                from datetime import datetime
                datetime.strptime(tags["CreatedDate"], "%Y-%m-%d")
            except ValueError:
                errors.append(f"Invalid CreatedDate format: {tags['CreatedDate']}")
        
        return errors

def main():
    """Validate tags in CDK stacks."""
    validator = TagValidator()
    
    test_tags = {
        "Environment": "dev",
        "Project": "lambda-monorepo",
        "Owner": "platform-team",
        "CostCenter": "ENG-001",
        "ManagedBy": "cdk",
        "CreatedDate": "2024-01-15",
        "DataClassification": "internal"
    }
    
    errors = validator.validate_tags(test_tags)
    
    if errors:
        print("❌ Tag validation errors:")
        for error in errors:
            print(f"  - {error}")
        return 1
    else:
        print("✅ All tags are valid")
        return 0

if __name__ == "__main__":
    sys.exit(main())

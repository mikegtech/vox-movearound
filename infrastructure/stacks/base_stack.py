from aws_cdk import Stack, Tags
from constructs import Construct
from typing import Dict, Any
from datetime import datetime
import os

class BaseStack(Stack):
    """Base stack with standard tagging and naming conventions."""
    
    def __init__(
        self, 
        scope: Construct, 
        construct_id: str,
        config: Dict[str, Any],
        **kwargs
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        self.config = config
        self.environment = config["environment"]
        self.company_code = config["company_code"]
        self.region_code = self._get_region_code()
        
        # Apply standard tags
        self._apply_standard_tags()
    
    def _get_region_code(self) -> str:
        """Convert AWS region to short code."""
        region_map = {
            "us-east-1": "use1",
            "us-west-2": "usw2",
            "eu-west-1": "euw1",
            "eu-central-1": "euc1",
            "ap-southeast-1": "apse1",
        }
        return region_map.get(self.region, self.region[:4])
    
    def _apply_standard_tags(self) -> None:
        """Apply mandatory tags to all resources in the stack."""
        Tags.of(self).add("Environment", self.environment)
        Tags.of(self).add("Project", self.config["project_name"])
        Tags.of(self).add("Owner", self.config["owner"])
        Tags.of(self).add("CostCenter", self.config["cost_center"])
        Tags.of(self).add("ManagedBy", "cdk")
        Tags.of(self).add("CreatedDate", datetime.now().strftime("%Y-%m-%d"))
        Tags.of(self).add("DataClassification", self.config.get("data_classification", "internal"))
        
        # Environment-specific tags
        if self.environment == "prd":
            Tags.of(self).add("SLA", self.config.get("sla", "99.9"))
            Tags.of(self).add("CriticalityLevel", self.config.get("criticality", "high"))
        elif self.environment == "dev":
            Tags.of(self).add("AutoShutdown", "true")
            Tags.of(self).add("Purpose", "development")
    
    def get_resource_name(self, service: str, resource_type: str, identifier: str) -> str:
        """Generate resource name following naming conventions."""
        return f"{self.company_code}-{self.environment}-{self.region_code}-{service}-{resource_type}-{identifier}"
    
    def get_stack_name(self, purpose: str) -> str:
        """Generate stack name following naming conventions."""
        return f"{self.company_code}-{self.environment}-{purpose}-stack"

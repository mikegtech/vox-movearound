import json
import os
from typing import Dict, Any
from common.utils import create_policy, validate_token
from common.models import AuthContext

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda authorizer function.
    
    Args:
        event: API Gateway Lambda authorizer event
        context: Lambda context
        
    Returns:
        IAM policy document
    """
    print(f"Event: {json.dumps(event)}")
    
    # Get the token from the event
    token = event.get("authorizationToken", "").replace("Bearer ", "")
    
    if not token:
        raise Exception("Unauthorized")
    
    try:
        # Validate the token (implement your logic)
        auth_context = validate_token(token)
        
        # Create and return the policy
        policy = create_policy(
            principal_id=auth_context.user_id,
            effect="Allow",
            resource=event["methodArn"],
            context=auth_context.to_dict()
        )
        
        return policy
        
    except Exception as e:
        print(f"Error: {e}")
        raise Exception("Unauthorized")

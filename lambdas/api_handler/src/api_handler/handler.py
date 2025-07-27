import json
from typing import Dict, Any
from common.utils import create_response
from common.models import ResponseModel

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    API handler Lambda function.
    
    Args:
        event: API Gateway Lambda proxy event
        context: Lambda context
        
    Returns:
        API Gateway Lambda proxy response
    """
    print(f"Event: {json.dumps(event)}")
    
    try:
        # Get auth context from authorizer
        auth_context = event.get("requestContext", {}).get("authorizer", {})
        user_id = auth_context.get("userId", "unknown")
        
        # Process the request
        response_data = {
            "message": "Hello from Lambda!",
            "userId": user_id,
            "timestamp": context.aws_request_id
        }
        
        return create_response(
            status_code=200,
            body=response_data
        )
        
    except Exception as e:
        print(f"Error: {e}")
        return create_response(
            status_code=500,
            body={"error": "Internal server error"}
        )

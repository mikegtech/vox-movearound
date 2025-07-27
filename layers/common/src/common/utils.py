import jwt
import json
import os
from typing import Dict, Any, Optional
from datetime import datetime, timezone
from .models import AuthContext

def validate_token(token: str) -> AuthContext:
    """Validate JWT token and return auth context."""
    secret_key = os.environ.get("JWT_SECRET", "your-secret-key")
    
    try:
        payload = jwt.decode(token, secret_key, algorithms=["HS256"])
        return AuthContext(
            user_id=payload["sub"],
            email=payload.get("email"),
            roles=payload.get("roles", []),
            expires_at=payload.get("exp")
        )
    except jwt.ExpiredSignatureError:
        raise jwt.InvalidTokenError("Token has expired")
    except jwt.InvalidTokenError:
        raise

def create_policy(principal_id: str, effect: str, resource: str, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Create IAM policy for API Gateway."""
    policy = {
        "principalId": principal_id,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [{
                "Action": "execute-api:Invoke",
                "Effect": effect,
                "Resource": resource
            }]
        }
    }
    if context:
        policy["context"] = {k: str(v) for k, v in context.items()}
    return policy

def create_response(status_code: int, body: Any, headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
    """Create API Gateway Lambda proxy response."""
    return {
        "statusCode": status_code,
        "headers": headers or {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps(body) if not isinstance(body, str) else body
    }

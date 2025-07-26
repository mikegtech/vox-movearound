import pytest
from unittest.mock import patch, MagicMock
from handler import lambda_handler

@pytest.fixture
def api_gateway_event():
    """API Gateway authorizer event fixture."""
    return {
        "type": "TOKEN",
        "authorizationToken": "Bearer valid-token",
        "methodArn": "arn:aws:execute-api:us-east-1:123456789012:api-id/stage/GET/resource"
    }

@pytest.fixture
def lambda_context():
    """Lambda context fixture."""
    context = MagicMock()
    context.function_name = "test-function"
    context.request_id = "test-request-id"
    return context

def test_lambda_handler_valid_token(api_gateway_event, lambda_context):
    """Test handler with valid token."""
    with patch("handler.validate_token") as mock_validate:
        mock_auth = MagicMock()
        mock_auth.user_id = "user123"
        mock_auth.to_dict.return_value = {"userId": "user123"}
        mock_validate.return_value = mock_auth
        
        with patch("handler.create_policy") as mock_create_policy:
            expected_policy = {
                "principalId": "user123",
                "policyDocument": {
                    "Version": "2012-10-17",
                    "Statement": [{
                        "Action": "execute-api:Invoke",
                        "Effect": "Allow",
                        "Resource": api_gateway_event["methodArn"]
                    }]
                }
            }
            mock_create_policy.return_value = expected_policy
            
            result = lambda_handler(api_gateway_event, lambda_context)
            
            assert result == expected_policy
            mock_validate.assert_called_once_with("valid-token")

def test_lambda_handler_missing_token(lambda_context):
    """Test handler with missing token."""
    event = {
        "type": "TOKEN",
        "authorizationToken": "",
        "methodArn": "arn:aws:execute-api:us-east-1:123456789012:api-id/stage/GET/resource"
    }
    
    with pytest.raises(Exception, match="Unauthorized"):
        lambda_handler(event, lambda_context)

def test_lambda_handler_invalid_token(api_gateway_event, lambda_context):
    """Test handler with invalid token."""
    with patch("handler.validate_token") as mock_validate:
        mock_validate.side_effect = Exception("Invalid token")
        
        with pytest.raises(Exception, match="Unauthorized"):
            lambda_handler(api_gateway_event, lambda_context)

"""Common constants used across Lambda functions."""

# API Response codes
HTTP_OK = 200
HTTP_CREATED = 201
HTTP_BAD_REQUEST = 400
HTTP_UNAUTHORIZED = 401
HTTP_FORBIDDEN = 403
HTTP_NOT_FOUND = 404
HTTP_INTERNAL_ERROR = 500

# Headers
CONTENT_TYPE_JSON = "application/json"
CONTENT_TYPE_TEXT = "text/plain"

# Error messages
ERROR_UNAUTHORIZED = "Unauthorized"
ERROR_INVALID_TOKEN = "Invalid token"
ERROR_TOKEN_EXPIRED = "Token has expired"
ERROR_INTERNAL = "Internal server error"

# Environment variables
ENV_LOG_LEVEL = "LOG_LEVEL"
ENV_ENVIRONMENT = "ENVIRONMENT"
ENV_JWT_SECRET = "JWT_SECRET"

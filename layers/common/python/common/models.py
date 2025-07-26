from dataclasses import dataclass, asdict
from typing import List, Optional
from datetime import datetime

@dataclass
class AuthContext:
    """Authentication context for authorized requests."""
    user_id: str
    email: Optional[str] = None
    roles: List[str] = None
    expires_at: Optional[int] = None
    
    def __post_init__(self):
        if self.roles is None:
            self.roles = []
    
    def to_dict(self) -> dict:
        """Convert to dictionary for API Gateway context."""
        return {
            "userId": self.user_id,
            "email": self.email or "",
            "roles": ",".join(self.roles),
            "expiresAt": str(self.expires_at) if self.expires_at else ""
        }
    
    def is_expired(self) -> bool:
        """Check if the auth context has expired."""
        if not self.expires_at:
            return False
        return datetime.now().timestamp() > self.expires_at

@dataclass
class ResponseModel:
    """Standard API response model."""
    success: bool
    data: Optional[Any] = None
    error: Optional[str] = None
    request_id: Optional[str] = None
    
    def to_dict(self) -> dict:
        """Convert to dictionary."""
        result = {"success": self.success}
        if self.data is not None:
            result["data"] = self.data
        if self.error:
            result["error"] = self.error
        if self.request_id:
            result["requestId"] = self.request_id
        return result

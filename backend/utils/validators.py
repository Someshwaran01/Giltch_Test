"""
Input Validation Utilities
Provides validation for common input types to prevent injection attacks
"""
import re
from typing import Optional, Tuple

class InputValidator:
    """Centralized input validation"""
    
    # Regex patterns
    USERNAME_PATTERN = re.compile(r'^[a-zA-Z0-9_-]{3,50}$')
    EMAIL_PATTERN = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    PARTICIPANT_ID_PATTERN = re.compile(r'^[A-Z]{2,10}\d{3,6}$')
    
    @staticmethod
    def validate_username(username: str) -> Tuple[bool, Optional[str]]:
        """
        Validate username format
        
        Returns:
            Tuple of (is_valid, error_message)
        """
        if not username:
            return False, "Username is required"
        
        if len(username) < 3:
            return False, "Username must be at least 3 characters"
        
        if len(username) > 50:
            return False, "Username must not exceed 50 characters"
        
        if not InputValidator.USERNAME_PATTERN.match(username):
            return False, "Username can only contain letters, numbers, hyphens and underscores"
        
        return True, None
    
    @staticmethod
    def validate_email(email: str) -> Tuple[bool, Optional[str]]:
        """
        Validate email format
        
        Returns:
            Tuple of (is_valid, error_message)
        """
        if not email:
            return False, "Email is required"
        
        if len(email) > 255:
            return False, "Email is too long"
        
        if not InputValidator.EMAIL_PATTERN.match(email):
            return False, "Invalid email format"
        
        return True, None
    
    @staticmethod
    def validate_password(password: str) -> Tuple[bool, Optional[str]]:
        """
        Validate password strength
        
        Returns:
            Tuple of (is_valid, error_message)
        """
        if not password:
            return False, "Password is required"
        
        if len(password) < 8:
            return False, "Password must be at least 8 characters"
        
        if len(password) > 128:
            return False, "Password is too long"
        
        # Optional: Add more strength requirements
        # has_upper = any(c.isupper() for c in password)
        # has_lower = any(c.islower() for c in password)
        # has_digit = any(c.isdigit() for c in password)
        
        return True, None
    
    @staticmethod
    def validate_participant_id(pid: str) -> Tuple[bool, Optional[str]]:
        """
        Validate participant ID format (e.g., SHCCSGF001)
        
        Returns:
            Tuple of (is_valid, error_message)
        """
        if not pid:
            return False, "Participant ID is required"
        
        # Allow numeric IDs or pattern-based IDs
        if pid.isdigit():
            return True, None
        
        if not InputValidator.PARTICIPANT_ID_PATTERN.match(pid):
            return False, "Invalid participant ID format"
        
        return True, None
    
    @staticmethod
    def sanitize_string(text: str, max_length: int = 1000) -> str:
        """
        Sanitize string input by removing potentially harmful characters
        
        Args:
            text: Input string
            max_length: Maximum allowed length
            
        Returns:
            Sanitized string
        """
        if not text:
            return ""
        
        # Trim to max length
        text = text[:max_length]
        
        # Remove null bytes
        text = text.replace('\x00', '')
        
        # Remove control characters except newline and tab
        text = ''.join(char for char in text if ord(char) >= 32 or char in '\n\t')
        
        return text.strip()
    
    @staticmethod
    def validate_json_keys(data: dict, required_keys: list, optional_keys: list = None) -> Tuple[bool, Optional[str]]:
        """
        Validate that JSON data has required keys and no unexpected keys
        
        Args:
            data: Dictionary to validate
            required_keys: List of required key names
            optional_keys: List of optional key names
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        if not isinstance(data, dict):
            return False, "Invalid data format"
        
        # Check required keys
        missing_keys = set(required_keys) - set(data.keys())
        if missing_keys:
            return False, f"Missing required fields: {', '.join(missing_keys)}"
        
        # Check for unexpected keys
        allowed_keys = set(required_keys) | set(optional_keys or [])
        unexpected_keys = set(data.keys()) - allowed_keys
        if unexpected_keys:
            return False, f"Unexpected fields: {', '.join(unexpected_keys)}"
        
        return True, None

# Global validator instance
validator = InputValidator()

"""
Password Utilities
Centralized password hashing and verification with multiple hash type support
"""
import hashlib
from typing import Tuple
from werkzeug.security import check_password_hash, generate_password_hash

class PasswordManager:
    """Centralized password management"""
    
    @staticmethod
    def verify_password(password: str, password_hash: str) -> bool:
        """
        Verify password against stored hash.
        Supports: SHA256, Scrypt, PBKDF2 (Werkzeug)
        
        Args:
            password: Plain text password
            password_hash: Stored password hash
            
        Returns:
            True if password matches, False otherwise
        """
        if not password or not password_hash:
            return False
        
        # Check if it's a SHA256 hash (64 hex characters)
        if len(password_hash) == 64 and all(c in '0123456789abcdef' for c in password_hash.lower()):
            input_hash = hashlib.sha256(password.encode()).hexdigest()
            return password_hash.lower() == input_hash.lower()
        
        # Check if it's a scrypt hash (starts with scrypt:)
        if password_hash.startswith('scrypt:'):
            try:
                return check_password_hash(password_hash, password)
            except Exception:
                return False
        
        # Try Werkzeug check (pbkdf2, etc.)
        try:
            return check_password_hash(password_hash, password)
        except Exception:
            return False
    
    @staticmethod
    def hash_password(password: str, method: str = 'pbkdf2') -> str:
        """
        Hash a password using specified method
        
        Args:
            password: Plain text password
            method: 'pbkdf2', 'scrypt', or 'sha256'
            
        Returns:
            Hashed password string
        """
        if method == 'sha256':
            return hashlib.sha256(password.encode()).hexdigest()
        elif method == 'scrypt':
            return generate_password_hash(password, method='scrypt')
        else:  # pbkdf2 (default)
            return generate_password_hash(password, method='pbkdf2:sha256')
    
    @staticmethod
    def get_hash_info(password_hash: str) -> Tuple[str, int]:
        """
        Get information about a password hash
        
        Returns:
            Tuple of (hash_type, hash_length)
        """
        if len(password_hash) == 64 and all(c in '0123456789abcdef' for c in password_hash.lower()):
            return ('sha256', len(password_hash))
        elif password_hash.startswith('scrypt:'):
            return ('scrypt', len(password_hash))
        elif password_hash.startswith('pbkdf2:'):
            return ('pbkdf2', len(password_hash))
        else:
            return ('unknown', len(password_hash))

# Global instance
password_manager = PasswordManager()

"""
Rate Limiting Utility
Provides simple in-memory rate limiting for login endpoints
For production, use Redis-based solution like Flask-Limiter
"""
import time
from collections import defaultdict
from threading import Lock
from config import Config

class SimpleRateLimiter:
    """Thread-safe in-memory rate limiter"""
    
    def __init__(self):
        self._attempts = defaultdict(list)
        self._lock = Lock()
        self._enabled = Config.RATELIMIT_ENABLED
        self._max_attempts = Config.RATELIMIT_LOGIN_ATTEMPTS
        self._window = Config.RATELIMIT_LOGIN_WINDOW
    
    def is_allowed(self, identifier: str) -> bool:
        """
        Check if the identifier is allowed to make a request
        
        Args:
            identifier: Unique identifier (e.g., username, IP address)
            
        Returns:
            True if allowed, False if rate limited
        """
        if not self._enabled:
            return True
        
        with self._lock:
            now = time.time()
            # Clean old attempts
            self._attempts[identifier] = [
                timestamp for timestamp in self._attempts[identifier]
                if now - timestamp < self._window
            ]
            
            # Check if limit exceeded
            if len(self._attempts[identifier]) >= self._max_attempts:
                return False
            
            # Record this attempt
            self._attempts[identifier].append(now)
            return True
    
    def get_remaining_time(self, identifier: str) -> int:
        """Get remaining time in seconds until rate limit resets"""
        if not self._enabled:
            return 0
            
        with self._lock:
            attempts = self._attempts.get(identifier, [])
            if not attempts:
                return 0
            
            oldest_attempt = min(attempts)
            elapsed = time.time() - oldest_attempt
            return max(0, int(self._window - elapsed))
    
    def reset(self, identifier: str):
        """Reset rate limit for a specific identifier"""
        with self._lock:
            if identifier in self._attempts:
                del self._attempts[identifier]

# Global rate limiter instance
rate_limiter = SimpleRateLimiter()

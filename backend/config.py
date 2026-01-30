import os
import secrets
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Security: Use environment variable for SECRET_KEY, generate strong default if missing
    _secret = os.getenv('SECRET_KEY')
    if not _secret or _secret == 'dev_secret_key':
        # Generate a secure random key if not set (for development only)
        _secret = secrets.token_hex(32)
        if os.getenv('FLASK_ENV') == 'production':
            raise ValueError("SECRET_KEY must be set in production environment")
    SECRET_KEY = _secret
    
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    DEBUG = os.getenv('FLASK_DEBUG', 'False') == 'True'  # Default to False for safety
    
    # Supabase
    SUPABASE_URL = os.getenv('SUPABASE_URL')
    SUPABASE_KEY = os.getenv('SUPABASE_KEY')
    
    # Frontend URL for CORS (restrict in production)
    FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:5000')
    ALLOWED_ORIGINS = os.getenv('ALLOWED_ORIGINS', FRONTEND_URL).split(',')
    
    # Security Headers
    SECURITY_HEADERS = {
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains'
    }
    
    # Rate Limiting
    RATELIMIT_ENABLED = os.getenv('RATELIMIT_ENABLED', 'True') == 'True'
    RATELIMIT_LOGIN_ATTEMPTS = int(os.getenv('RATELIMIT_LOGIN_ATTEMPTS', '5'))
    RATELIMIT_LOGIN_WINDOW = int(os.getenv('RATELIMIT_LOGIN_WINDOW', '300'))  # 5 minutes
    
    # JWT Configuration
    JWT_EXPIRY_HOURS = int(os.getenv('JWT_EXPIRY_HOURS', '24'))
    JWT_ALGORITHM = 'HS256'
    
    # Database Configuration
    DB_POOL_SIZE = int(os.getenv('DB_POOL_SIZE', '30'))
    DB_POOL_TIMEOUT = int(os.getenv('DB_POOL_TIMEOUT', '30'))
    DB_MAX_RETRIES = int(os.getenv('DB_MAX_RETRIES', '3'))
    
    # Mail Config (Optional placeholder)
    MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.getenv('MAIL_PORT', 587))
    MAIL_USE_TLS = True
    MAIL_USERNAME = os.getenv('MAIL_USERNAME')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD')

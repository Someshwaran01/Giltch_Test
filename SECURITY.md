# Security Guidelines

## Overview
This document outlines security best practices and implementations in the Debug Marathon Platform.

## Security Features Implemented

### 1. Authentication & Authorization
- **JWT-based authentication** with configurable expiry (default 24 hours)
- **Role-based access control** (Admin, Leader, Participant)
- **Password hashing** using PBKDF2, Scrypt, or SHA256
- **Rate limiting** on login endpoints (5 attempts per 5 minutes)
- **Token validation** on all protected routes

### 2. Input Validation
- **Centralized validation** for usernames, emails, passwords
- **SQL injection prevention** using parameterized queries
- **XSS protection** through input sanitization
- **Request size limits** (10MB maximum)

### 3. Network Security
- **CORS configured** with explicit allowed origins
- **Security headers** enabled:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `X-XSS-Protection: 1; mode=block`
  - `Strict-Transport-Security` for HTTPS
- **Request timeouts** (30 seconds) to prevent hanging connections

### 4. Database Security
- **Connection pooling** with timeout limits
- **Prepared statements** for all queries
- **Retry logic** with exponential backoff
- **Automatic connection cleanup**
- **Environment-based credentials** (never hardcoded)

### 5. Error Handling
- **No sensitive data** leaked in error messages
- **Structured logging** for security events
- **Different error messages** for dev vs production
- **Graceful degradation** on failures

## Configuration Checklist

### Production Deployment
- [ ] Set strong `SECRET_KEY` (use `secrets.token_hex(32)`)
- [ ] Set `FLASK_DEBUG=False`
- [ ] Restrict `ALLOWED_ORIGINS` to your domain
- [ ] Use HTTPS for all endpoints
- [ ] Enable rate limiting (`RATELIMIT_ENABLED=True`)
- [ ] Configure database connection limits
- [ ] Set up logging and monitoring
- [ ] Review and restrict CORS settings

### Password Requirements
- Minimum 8 characters
- Stored using PBKDF2-SHA256 or Scrypt
- Never logged or displayed
- Rate-limited login attempts

### Rate Limiting
- Login endpoints: 5 attempts per 5 minutes
- Configurable via environment variables
- Per-user tracking (by username or IP)
- Automatic reset on successful login

## Security Best Practices

### For Developers
1. **Never commit secrets** - Use `.env` files (add to `.gitignore`)
2. **Validate all inputs** - Use `validators.py` utilities
3. **Use parameterized queries** - Never string concatenation
4. **Log security events** - Failed logins, access violations
5. **Keep dependencies updated** - Regular `pip install --upgrade`

### For Administrators
1. **Monitor logs** regularly for suspicious activity
2. **Review user access** periodically
3. **Backup database** regularly
4. **Update credentials** if compromised
5. **Test disaster recovery** procedures

### For Users
1. **Use strong passwords** (8+ characters)
2. **Never share credentials**
3. **Report suspicious activity**
4. **Logout after use** on shared computers

## Incident Response

If you discover a security vulnerability:
1. **Do not disclose publicly**
2. **Email the security team** immediately
3. **Provide detailed information**:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Audit Log

| Date | Issue | Severity | Status | Fixed By |
|------|-------|----------|--------|----------|
| 2026-01-30 | Debug prints exposing passwords | High | Fixed | Code Review |
| 2026-01-30 | No rate limiting on login | High | Fixed | Code Review |
| 2026-01-30 | Hardcoded SECRET_KEY | Critical | Fixed | Code Review |
| 2026-01-30 | CORS allows all origins | Medium | Fixed | Code Review |
| 2026-01-30 | No request timeouts | Medium | Fixed | Code Review |

## Updates

This document is reviewed quarterly and updated as needed.
Last reviewed: January 30, 2026

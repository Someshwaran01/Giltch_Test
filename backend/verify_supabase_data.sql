-- ============================================================
-- SUPABASE DATABASE VERIFICATION QUERIES
-- Run these in Supabase SQL Editor to verify your data
-- ============================================================

-- 1. Check if admin user exists
SELECT 
    user_id,
    username, 
    email,
    role,
    admin_status,
    LENGTH(password_hash) as hash_length,
    SUBSTRING(password_hash, 1, 20) || '...' as hash_preview
FROM users 
WHERE username = 'admin' AND role = 'admin';

-- Expected result:
-- user_id: 7317
-- username: admin
-- email: admin@debugmarathon.com
-- role: admin
-- admin_status: APPROVED
-- hash_length: 64
-- hash_preview: 240be518fabd2724ddb6...

-- ============================================================

-- 2. Check if leader1 user exists  
SELECT 
    user_id,
    username,
    email,
    role,
    admin_status,
    LENGTH(password_hash) as hash_length,
    SUBSTRING(password_hash, 1, 20) || '...' as hash_preview
FROM users 
WHERE username = 'leader1' AND role = 'leader';

-- Expected result:
-- user_id: 7318
-- username: leader1
-- email: leader1@college.edu
-- role: leader
-- admin_status: APPROVED
-- hash_length: 64

-- ============================================================

-- 3. Count all users by role
SELECT role, admin_status, COUNT(*) as count
FROM users
GROUP BY role, admin_status
ORDER BY role;

-- Expected results:
-- admin | APPROVED | 1
-- leader | APPROVED | 2
-- participant | PENDING | ~14

-- ============================================================

-- 4. Check if contests table has data
SELECT contest_id, contest_name, status, current_round
FROM contests
WHERE contest_id = 1;

-- Expected result:
-- contest_id: 1
-- contest_name: Debug Marathon 2026
-- status: live
-- current_round: 1

-- ============================================================

-- 5. Verify password hash format
SELECT 
    username,
    password_hash,
    CASE
        WHEN LENGTH(password_hash) = 64 
             AND password_hash ~ '^[0-9a-f]{64}$' 
        THEN 'SHA256 ✓'
        WHEN password_hash LIKE 'scrypt:%' 
        THEN 'SCRYPT ✓'
        WHEN password_hash LIKE 'pbkdf2:%' 
        THEN 'PBKDF2 ✓'
        ELSE 'UNKNOWN ✗'
    END as hash_type
FROM users
WHERE username IN ('admin', 'leader1', 'ak27')
ORDER BY username;

-- Expected results:
-- admin | 240be518... | SHA256 ✓
-- ak27 | scrypt:... | SCRYPT ✓
-- leader1 | 6b4b7f0b... | SHA256 ✓

-- ============================================
-- Cleanup Script: Remove All Test Data
-- Run this in Supabase SQL Editor
-- ============================================

-- WARNING: This will permanently delete all test users and their data!
-- Make sure to backup first if needed

-- Simple version: Just delete test users
-- Foreign keys should cascade delete related records
DELETE FROM users WHERE username LIKE 'TEST%';

-- Verify deletion
SELECT COUNT(*) as deleted_test_users FROM users WHERE username LIKE 'TEST%';
-- Expected: 0


-- ============================================
-- Alternative: Manual cleanup (if cascade doesn't work)
-- Run these one by one if you get foreign key errors
-- ============================================

/*
-- Step 1: Delete submissions from test participants
DELETE FROM submissions 
WHERE participant_id IN (
    SELECT user_id FROM users WHERE username LIKE 'TEST%'
);

-- Step 2: Delete contest participants records
DELETE FROM contest_participants 
WHERE participant_id IN (
    SELECT user_id FROM users WHERE username LIKE 'TEST%'
);

-- Step 3: Delete test users
DELETE FROM users WHERE username LIKE 'TEST%';

-- Verify
SELECT COUNT(*) FROM users WHERE username LIKE 'TEST%';
*/

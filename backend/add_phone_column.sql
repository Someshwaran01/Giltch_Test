-- Add phone column to users table for participant import functionality
-- Run this on your Supabase database

ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Create index for faster phone lookups
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- Update existing users with NULL phone if needed
UPDATE users SET phone = NULL WHERE phone IS NULL;

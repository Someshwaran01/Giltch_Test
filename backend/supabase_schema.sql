-- PostgreSQL Database Setup for Debug Marathon (Supabase Compatible)
-- Version: 5.0 - Unified Users Table

-- --------------------------------------------------------
-- CLEANUP: Drop all existing tables to start fresh
-- --------------------------------------------------------
DROP TABLE IF EXISTS violations CASCADE;
DROP TABLE IF EXISTS leaderboard CASCADE;
DROP MATERIALIZED VIEW IF EXISTS leaderboard CASCADE;
DROP TABLE IF EXISTS admin_state CASCADE;
DROP TABLE IF EXISTS proctoring_config CASCADE;
DROP TABLE IF EXISTS contest_participants CASCADE;
DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS rounds CASCADE;
DROP TABLE IF EXISTS contests CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS participants CASCADE;
DROP TABLE IF EXISTS leaders CASCADE;
DROP TABLE IF EXISTS contest_submissions CASCADE;
DROP TABLE IF EXISTS proctoring_violations CASCADE;
DROP TABLE IF EXISTS participant_stats CASCADE;

-- --------------------------------------------------------
-- 1. Users Table (Unified: Leaders + Participants)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100),
  role VARCHAR(20) NOT NULL DEFAULT 'participant',
  department VARCHAR(100),
  college VARCHAR(100),
  phone VARCHAR(20),
  status VARCHAR(20) DEFAULT 'active',
  is_active BOOLEAN DEFAULT TRUE,
  admin_status VARCHAR(20) DEFAULT 'PENDING',
  approved_by INTEGER,
  approval_at TIMESTAMP,
  profile_image VARCHAR(255),
  registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP
);

-- --------------------------------------------------------
-- 2. Contests Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS contests (
  contest_id SERIAL PRIMARY KEY,
  contest_name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Timing
  start_datetime TIMESTAMP NOT NULL,
  end_datetime TIMESTAMP NOT NULL,
  duration_minutes INTEGER,
  
  -- Status
  status VARCHAR(20) DEFAULT 'draft',
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Settings
  max_violations_allowed INTEGER DEFAULT 5,
  current_round INTEGER DEFAULT 1,
  
  -- Meta
  created_by INTEGER REFERENCES users(user_id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- 3. Rounds Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS rounds (
  round_id SERIAL PRIMARY KEY,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  round_name VARCHAR(100) NOT NULL,
  round_number INTEGER NOT NULL,
  time_limit_minutes INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  passing_score DECIMAL(5,2),
  status VARCHAR(20) DEFAULT 'pending',
  is_locked BOOLEAN DEFAULT TRUE,
  unlock_condition TEXT,
  allowed_language VARCHAR(50) DEFAULT 'python',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(contest_id, round_number)
);

-- --------------------------------------------------------
-- 4. Questions Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS questions (
  question_id SERIAL PRIMARY KEY,
  round_id INTEGER REFERENCES rounds(round_id) ON DELETE CASCADE,
  question_number INTEGER NOT NULL,
  question_title VARCHAR(255) NOT NULL,
  question_description TEXT,
  difficulty_level VARCHAR(20),
  expected_output TEXT,
  test_cases JSONB,
  sample_input TEXT,
  sample_output TEXT,
  points INTEGER DEFAULT 10,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(round_id, question_number)
);

-- --------------------------------------------------------
-- 5. Submissions Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS submissions (
  submission_id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  question_id INTEGER NOT NULL REFERENCES questions(question_id) ON DELETE CASCADE,
  contest_id INTEGER REFERENCES contests(contest_id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  language VARCHAR(50) DEFAULT 'python',
  is_correct BOOLEAN DEFAULT FALSE,
  score_awarded DECIMAL(5,2) DEFAULT 0,
  execution_time_ms INTEGER,
  test_cases_passed INTEGER DEFAULT 0,
  total_test_cases INTEGER DEFAULT 0,
  error_message TEXT,
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- 6. Contest Participants Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS contest_participants (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  current_round INTEGER DEFAULT 1,
  current_question INTEGER DEFAULT 0,
  total_score DECIMAL(10,2) DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active',
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  UNIQUE(user_id, contest_id)
);

-- --------------------------------------------------------
-- 7. Proctoring Configuration Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS proctoring_config (
  id SERIAL PRIMARY KEY,
  contest_id INTEGER REFERENCES contests(contest_id) ON DELETE CASCADE UNIQUE,
  proctoring_enabled BOOLEAN DEFAULT TRUE,
  auto_disqualify_enabled BOOLEAN DEFAULT TRUE,
  max_violations INTEGER DEFAULT 5,
  tab_switch_penalty INTEGER DEFAULT 5,
  copy_paste_penalty INTEGER DEFAULT 10,
  screenshot_penalty INTEGER DEFAULT 15,
  focus_loss_penalty INTEGER DEFAULT 3,
  warning_threshold INTEGER DEFAULT 3,
  critical_threshold INTEGER DEFAULT 5,
  block_copy BOOLEAN DEFAULT TRUE,
  block_paste BOOLEAN DEFAULT TRUE,
  block_screenshot BOOLEAN DEFAULT TRUE,
  block_right_click BOOLEAN DEFAULT TRUE,
  grace_violations INTEGER DEFAULT 2,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- 8. Violations Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS violations (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  contest_id INTEGER REFERENCES contests(contest_id) ON DELETE CASCADE,
  violation_type VARCHAR(50) NOT NULL,
  violation_severity VARCHAR(20),
  description TEXT,
  question_id INTEGER REFERENCES questions(question_id),
  detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  penalty_points INTEGER DEFAULT 0
);

-- --------------------------------------------------------
-- 9. Leaderboard Table
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS leaderboard (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  rank INTEGER,
  total_score DECIMAL(10,2) DEFAULT 0,
  questions_solved INTEGER DEFAULT 0,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, contest_id)
);

-- --------------------------------------------------------
-- 10. Admin State Table (for contest control)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_state (
  id SERIAL PRIMARY KEY,
  contest_id INTEGER REFERENCES contests(contest_id) ON DELETE CASCADE UNIQUE,
  active_round INTEGER DEFAULT 0,
  active_question INTEGER DEFAULT 0,
  is_paused BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- Indexes for Performance
-- --------------------------------------------------------

-- Users
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- Submissions
CREATE INDEX IF NOT EXISTS idx_submissions_user ON submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_submissions_question ON submissions(question_id);
CREATE INDEX IF NOT EXISTS idx_submissions_contest ON submissions(contest_id);
CREATE INDEX IF NOT EXISTS idx_submissions_timestamp ON submissions(submitted_at DESC);

-- Violations
CREATE INDEX IF NOT EXISTS idx_violations_user ON violations(user_id);
CREATE INDEX IF NOT EXISTS idx_violations_contest ON violations(contest_id);
CREATE INDEX IF NOT EXISTS idx_violations_timestamp ON violations(detected_at DESC);

-- Contest Participants
CREATE INDEX IF NOT EXISTS idx_contest_participants_user ON contest_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_contest_participants_contest ON contest_participants(contest_id);

-- Leaderboard
CREATE INDEX IF NOT EXISTS idx_leaderboard_contest ON leaderboard(contest_id, rank);
CREATE INDEX IF NOT EXISTS idx_leaderboard_user ON leaderboard(user_id);

-- --------------------------------------------------------
-- Sample Data (Optional - for testing)
-- --------------------------------------------------------

-- Insert default admin user
INSERT INTO users (username, password_hash, full_name, email, role)
VALUES (
  'admin',
  'pbkdf2:sha256:600000$default$9ef8f1b98c9e8b8d9e8c9d8e9f8e9d8c',
  'Administrator',
  'admin@debugmarathon.com',
  'admin'
) ON CONFLICT (username) DO NOTHING;

-- Insert sample contest
INSERT INTO contests (contest_name, description, status, start_datetime, end_datetime, created_by)
VALUES (
  'Debug Marathon 2026',
  'Annual debugging competition for computer science students',
  'draft',
  '2026-03-01 09:00:00',
  '2026-03-01 18:00:00',
  (SELECT user_id FROM users WHERE username='admin' LIMIT 1)
) ON CONFLICT DO NOTHING;

-- --------------------------------------------------------
-- Functions (Optional)
-- --------------------------------------------------------

-- Refresh leaderboard function (if needed)
CREATE OR REPLACE FUNCTION update_leaderboard_ranks()
RETURNS void AS $$
BEGIN
    UPDATE leaderboard l
    SET rank = sub.row_num
    FROM (
        SELECT user_id, contest_id,
               ROW_NUMBER() OVER (PARTITION BY contest_id ORDER BY total_score DESC) as row_num
        FROM leaderboard
    ) sub
    WHERE l.user_id = sub.user_id AND l.contest_id = sub.contest_id;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------
-- Complete!
-- --------------------------------------------------------

-- Schema setup complete for Debug Marathon Platform - PostgreSQL/Supabase v5.0

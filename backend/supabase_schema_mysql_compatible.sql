-- PostgreSQL Schema for Debug Marathon (MySQL Compatible)
-- This matches the original MySQL structure exactly

-- Drop existing tables if needed
DROP TABLE IF EXISTS violations CASCADE;
DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS shortlisted_participants CASCADE;
DROP TABLE IF EXISTS participant_level_stats CASCADE;
DROP TABLE IF EXISTS leaderboard CASCADE;
DROP TABLE IF EXISTS participant_proctoring CASCADE;
DROP TABLE IF EXISTS proctoring_alerts CASCADE;
DROP TABLE IF EXISTS proctoring_logs CASCADE;
DROP TABLE IF EXISTS proctoring_config CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS rounds CASCADE;
DROP TABLE IF EXISTS contests CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS admin_state CASCADE;

-- 1. ADMIN STATE TABLE
CREATE TABLE admin_state (
  key_name VARCHAR(100) PRIMARY KEY,
  value TEXT,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. USERS TABLE
CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100),
  role VARCHAR(20) NOT NULL DEFAULT 'participant',
  department VARCHAR(100),
  college VARCHAR(100),
  status VARCHAR(20) DEFAULT 'active',
  is_active BOOLEAN DEFAULT TRUE,
  admin_status VARCHAR(20) DEFAULT 'PENDING',
  approved_by INTEGER,
  approval_at TIMESTAMP,
  profile_image VARCHAR(255),
  registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP
);

-- 3. CONTESTS TABLE
CREATE TABLE contests (
  contest_id SERIAL PRIMARY KEY,
  contest_name VARCHAR(255) NOT NULL,
  description TEXT,
  start_datetime TIMESTAMP NOT NULL,
  end_datetime TIMESTAMP NOT NULL,
  status VARCHAR(20) DEFAULT 'draft',
  is_active BOOLEAN DEFAULT TRUE,
  max_violations_allowed INTEGER DEFAULT 5,
  current_round INTEGER DEFAULT 1,
  created_by INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. ROUNDS TABLE
CREATE TABLE rounds (
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

-- 5. QUESTIONS TABLE
CREATE TABLE questions (
  question_id SERIAL PRIMARY KEY,
  round_id INTEGER NOT NULL REFERENCES rounds(round_id) ON DELETE CASCADE,
  question_number INTEGER NOT NULL,
  question_title VARCHAR(500) NOT NULL,
  question_description TEXT NOT NULL,
  buggy_code TEXT NOT NULL,
  expected_output TEXT,
  test_cases JSONB,
  difficulty_level VARCHAR(20) NOT NULL,
  points INTEGER DEFAULT 10,
  hints TEXT,
  time_estimate_minutes INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  test_input TEXT,
  UNIQUE(round_id, question_number)
);

-- 6. SUBMISSIONS TABLE
CREATE TABLE submissions (
  submission_id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  round_id INTEGER NOT NULL REFERENCES rounds(round_id) ON DELETE CASCADE,
  question_id INTEGER NOT NULL REFERENCES questions(question_id) ON DELETE CASCADE,
  submitted_code TEXT,
  is_correct BOOLEAN,
  score_awarded DECIMAL(5,2) DEFAULT 0.00,
  test_results JSONB,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  time_taken_seconds INTEGER,
  submission_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. LEADERBOARD TABLE
CREATE TABLE leaderboard (
  leaderboard_id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  rank_position INTEGER,
  total_score DECIMAL(7,2) DEFAULT 0.00,
  total_time_taken_seconds INTEGER DEFAULT 0,
  questions_attempted INTEGER DEFAULT 0,
  questions_correct INTEGER DEFAULT 0,
  violations_count INTEGER DEFAULT 0,
  current_round INTEGER DEFAULT 1,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, contest_id)
);

-- 8. PARTICIPANT LEVEL STATS TABLE
CREATE TABLE participant_level_stats (
  stat_id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  level INTEGER NOT NULL,
  status VARCHAR(20) DEFAULT 'NOT_STARTED',
  questions_solved INTEGER DEFAULT 0,
  level_score DECIMAL(5,2) DEFAULT 0.00,
  violation_count INTEGER DEFAULT 0,
  start_time TIMESTAMP,
  completed_at TIMESTAMP,
  run_count INTEGER DEFAULT 0,
  UNIQUE(user_id, contest_id, level)
);

-- 9. PROCTORING CONFIG TABLE
CREATE TABLE proctoring_config (
  id VARCHAR(36) PRIMARY KEY,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE UNIQUE,
  enabled BOOLEAN DEFAULT TRUE,
  max_violations INTEGER DEFAULT 10,
  auto_disqualify BOOLEAN DEFAULT TRUE,
  warning_threshold INTEGER DEFAULT 5,
  grace_violations INTEGER DEFAULT 2,
  strict_mode BOOLEAN DEFAULT FALSE,
  track_tab_switches BOOLEAN DEFAULT TRUE,
  track_focus_loss BOOLEAN DEFAULT TRUE,
  block_copy BOOLEAN DEFAULT TRUE,
  block_paste BOOLEAN DEFAULT TRUE,
  block_cut BOOLEAN DEFAULT TRUE,
  block_selection BOOLEAN DEFAULT FALSE,
  block_right_click BOOLEAN DEFAULT TRUE,
  detect_screenshot BOOLEAN DEFAULT TRUE,
  tab_switch_penalty INTEGER DEFAULT 1,
  copy_paste_penalty INTEGER DEFAULT 2,
  screenshot_penalty INTEGER DEFAULT 3,
  focus_loss_penalty INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. PARTICIPANT PROCTORING TABLE
CREATE TABLE participant_proctoring (
  id VARCHAR(36) PRIMARY KEY,
  participant_id VARCHAR(100),
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  risk_level VARCHAR(20) DEFAULT 'low',
  total_violations INTEGER DEFAULT 0,
  violation_score INTEGER DEFAULT 0,
  extra_violations INTEGER DEFAULT 0,
  is_disqualified BOOLEAN DEFAULT FALSE,
  disqualified_at TIMESTAMP,
  disqualification_reason TEXT,
  is_suspended BOOLEAN DEFAULT FALSE,
  suspended_at TIMESTAMP,
  suspension_reason TEXT,
  last_heartbeat TIMESTAMP,
  client_ip VARCHAR(45),
  tab_switches INTEGER DEFAULT 0,
  focus_losses INTEGER DEFAULT 0,
  copy_attempts INTEGER DEFAULT 0,
  paste_attempts INTEGER DEFAULT 0,
  screenshot_attempts INTEGER DEFAULT 0,
  last_violation_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(participant_id, contest_id)
);

-- 11. PROCTORING ALERTS TABLE
CREATE TABLE proctoring_alerts (
  id SERIAL PRIMARY KEY,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  participant_id VARCHAR(100),
  alert_type VARCHAR(50) NOT NULL,
  severity VARCHAR(20) DEFAULT 'warning',
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. PROCTORING LOGS TABLE
CREATE TABLE proctoring_logs (
  id VARCHAR(36) PRIMARY KEY,
  contest_id INTEGER REFERENCES contests(contest_id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  participant_id VARCHAR(100),
  action_type VARCHAR(50) NOT NULL,
  action_by VARCHAR(100),
  details JSONB,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. SHORTLISTED PARTICIPANTS TABLE
CREATE TABLE shortlisted_participants (
  id SERIAL PRIMARY KEY,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  level INTEGER NOT NULL,
  is_allowed BOOLEAN DEFAULT TRUE,
  UNIQUE(contest_id, level, user_id)
);

-- 14. VIOLATIONS TABLE
CREATE TABLE violations (
  violation_id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
  round_id INTEGER REFERENCES rounds(round_id) ON DELETE CASCADE,
  question_id INTEGER REFERENCES questions(question_id) ON DELETE CASCADE,
  violation_type VARCHAR(50) NOT NULL,
  description TEXT,
  severity VARCHAR(20) NOT NULL DEFAULT 'medium',
  penalty_points INTEGER DEFAULT 1,
  level INTEGER DEFAULT 1,
  ip_address VARCHAR(45),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- INDEXES
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_submissions_user ON submissions(user_id);
CREATE INDEX idx_submissions_contest ON submissions(contest_id);
CREATE INDEX idx_leaderboard_contest ON leaderboard(contest_id);
CREATE INDEX idx_violations_user ON violations(user_id);
CREATE INDEX idx_violations_contest ON violations(contest_id);

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers
DROP TRIGGER IF EXISTS update_proctoring_config_updated_at ON proctoring_config;
CREATE TRIGGER update_proctoring_config_updated_at BEFORE UPDATE ON proctoring_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_participant_proctoring_updated_at ON participant_proctoring;
CREATE TRIGGER update_participant_proctoring_updated_at BEFORE UPDATE ON participant_proctoring
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Schema creation complete

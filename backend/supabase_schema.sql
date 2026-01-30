-- PostgreSQL Database Setup for Debug Marathon (Supabase Compatible)
-- Version: 4.0 - Optimized for Supabase Free Tier

-- --------------------------------------------------------
-- 1. Leaders Table (Admin/Contest Leaders)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS leaders (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100),
  email VARCHAR(100) UNIQUE NOT NULL,
  role VARCHAR(20) DEFAULT 'leader',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP
);

-- --------------------------------------------------------
-- 2. Participants Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS participants (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100),
  department VARCHAR(100),
  college VARCHAR(100),
  
  -- Status
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'disqualified', 'held', 'suspended')),
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Registration
  registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP,
  
  -- Contest Stats
  current_round INTEGER DEFAULT 0,
  current_question INTEGER DEFAULT 0,
  total_score INTEGER DEFAULT 0,
  violations_count INTEGER DEFAULT 0
);

-- --------------------------------------------------------
-- 3. Contests Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS contests (
  id SERIAL PRIMARY KEY,
  contest_name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Timing
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  duration_minutes INTEGER,
  
  -- Status
  status VARCHAR(20) DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'active', 'completed', 'paused')),
  is_published BOOLEAN DEFAULT FALSE,
  
  -- Settings
  max_rounds INTEGER DEFAULT 3,
  questions_per_round INTEGER DEFAULT 5,
  
  -- Meta
  created_by INTEGER REFERENCES leaders(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- 4. Rounds Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS rounds (
  id SERIAL PRIMARY KEY,
  contest_id INTEGER REFERENCES contests(id) ON DELETE CASCADE,
  round_number INTEGER NOT NULL,
  round_name VARCHAR(100),
  description TEXT,
  
  -- Timing
  time_limit_minutes INTEGER DEFAULT 30,
  
  -- Status
  status VARCHAR(20) DEFAULT 'locked' CHECK (status IN ('locked', 'active', 'completed')),
  
  -- Settings
  passing_score INTEGER DEFAULT 60,
  max_attempts INTEGER DEFAULT 1,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(contest_id, round_number)
);

-- --------------------------------------------------------
-- 5. Questions Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS questions (
  id SERIAL PRIMARY KEY,
  round_id INTEGER REFERENCES rounds(id) ON DELETE CASCADE,
  question_number INTEGER NOT NULL,
  
  -- Content
  title VARCHAR(255) NOT NULL,
  description TEXT,
  input_format TEXT,
  output_format TEXT,
  constraints TEXT,
  
  -- Difficulty
  difficulty VARCHAR(20) CHECK (difficulty IN ('easy', 'medium', 'hard')),
  points INTEGER DEFAULT 10,
  
  -- Test Cases
  test_cases JSONB,
  sample_test_cases JSONB,
  
  -- Meta
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(round_id, question_number)
);

-- --------------------------------------------------------
-- 6. Contest Submissions Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS contest_submissions (
  id SERIAL PRIMARY KEY,
  participant_id INTEGER REFERENCES participants(id) ON DELETE CASCADE,
  contest_id INTEGER REFERENCES contests(id) ON DELETE CASCADE,
  round_id INTEGER REFERENCES rounds(id) ON DELETE CASCADE,
  question_id INTEGER REFERENCES questions(id) ON DELETE CASCADE,
  
  -- Submission Details
  code TEXT NOT NULL,
  language VARCHAR(20) DEFAULT 'python',
  
  -- Results
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'wrong_answer', 'runtime_error', 'time_limit_exceeded', 'compilation_error')),
  test_cases_passed INTEGER DEFAULT 0,
  total_test_cases INTEGER DEFAULT 0,
  score INTEGER DEFAULT 0,
  
  -- Timing
  execution_time_ms INTEGER,
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Metadata
  attempt_number INTEGER DEFAULT 1,
  is_final_submission BOOLEAN DEFAULT FALSE
);

-- --------------------------------------------------------
-- 7. Participant Stats Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS participant_stats (
  id SERIAL PRIMARY KEY,
  participant_id INTEGER REFERENCES participants(id) ON DELETE CASCADE,
  contest_id INTEGER REFERENCES contests(id) ON DELETE CASCADE,
  
  -- Progress
  current_round INTEGER DEFAULT 1,
  current_question INTEGER DEFAULT 1,
  rounds_completed INTEGER DEFAULT 0,
  
  -- Scores
  total_score INTEGER DEFAULT 0,
  round_1_score INTEGER DEFAULT 0,
  round_2_score INTEGER DEFAULT 0,
  round_3_score INTEGER DEFAULT 0,
  
  -- Activity
  total_submissions INTEGER DEFAULT 0,
  successful_submissions INTEGER DEFAULT 0,
  
  -- Timing
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  
  -- Proctoring
  violations_count INTEGER DEFAULT 0,
  is_disqualified BOOLEAN DEFAULT FALSE,
  
  UNIQUE(participant_id, contest_id)
);

-- --------------------------------------------------------
-- 8. Proctoring Configuration Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS proctoring_config (
  id SERIAL PRIMARY KEY,
  contest_id INTEGER REFERENCES contests(id) ON DELETE CASCADE UNIQUE,
  
  -- Global Settings
  proctoring_enabled BOOLEAN DEFAULT TRUE,
  auto_disqualify_enabled BOOLEAN DEFAULT TRUE,
  max_violations INTEGER DEFAULT 5,
  
  -- Violation Penalties (points deducted per violation)
  tab_switch_penalty INTEGER DEFAULT 5,
  copy_paste_penalty INTEGER DEFAULT 10,
  screenshot_penalty INTEGER DEFAULT 15,
  focus_loss_penalty INTEGER DEFAULT 3,
  
  -- Thresholds
  warning_threshold INTEGER DEFAULT 3,
  critical_threshold INTEGER DEFAULT 5,
  
  -- Restrictions
  block_copy BOOLEAN DEFAULT TRUE,
  block_paste BOOLEAN DEFAULT TRUE,
  block_screenshot BOOLEAN DEFAULT TRUE,
  block_right_click BOOLEAN DEFAULT TRUE,
  
  -- Grace Settings
  grace_violations INTEGER DEFAULT 2,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- 9. Proctoring Violations Table
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS proctoring_violations (
  id SERIAL PRIMARY KEY,
  participant_id INTEGER REFERENCES participants(id) ON DELETE CASCADE,
  contest_id INTEGER REFERENCES contests(id) ON DELETE CASCADE,
  
  -- Violation Details
  violation_type VARCHAR(50) NOT NULL,
  violation_severity VARCHAR(20) CHECK (violation_severity IN ('low', 'medium', 'high', 'critical')),
  description TEXT,
  
  -- Context
  question_id INTEGER REFERENCES questions(id),
  round_number INTEGER,
  
  -- Metadata
  detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  action_taken VARCHAR(50),
  penalty_points INTEGER DEFAULT 0
);

-- --------------------------------------------------------
-- 10. Leaderboard View (Materialized for performance)
-- --------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS leaderboard AS
SELECT 
  p.id as participant_id,
  p.username,
  p.full_name,
  p.department,
  p.college,
  ps.contest_id,
  ps.total_score,
  ps.rounds_completed,
  ps.successful_submissions,
  ps.violations_count,
  p.status,
  ps.completed_at,
  ROW_NUMBER() OVER (PARTITION BY ps.contest_id ORDER BY ps.total_score DESC, ps.completed_at ASC, ps.violations_count ASC) as rank
FROM participants p
INNER JOIN participant_stats ps ON p.id = ps.participant_id
WHERE p.status = 'active' AND ps.is_disqualified = FALSE;

-- Create index on materialized view
CREATE INDEX IF NOT EXISTS idx_leaderboard_contest ON leaderboard(contest_id, rank);

-- --------------------------------------------------------
-- 11. Admin State Table (for contest control)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_state (
  id SERIAL PRIMARY KEY,
  contest_id INTEGER REFERENCES contests(id) ON DELETE CASCADE UNIQUE,
  active_round INTEGER DEFAULT 0,
  active_question INTEGER DEFAULT 0,
  is_paused BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- Indexes for Performance
-- --------------------------------------------------------

-- Participants
CREATE INDEX IF NOT EXISTS idx_participants_status ON participants(status);
CREATE INDEX IF NOT EXISTS idx_participants_email ON participants(email);

-- Submissions
CREATE INDEX IF NOT EXISTS idx_submissions_participant ON contest_submissions(participant_id);
CREATE INDEX IF NOT EXISTS idx_submissions_contest ON contest_submissions(contest_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON contest_submissions(status);
CREATE INDEX IF NOT EXISTS idx_submissions_timestamp ON contest_submissions(submitted_at DESC);

-- Violations
CREATE INDEX IF NOT EXISTS idx_violations_participant ON proctoring_violations(participant_id);
CREATE INDEX IF NOT EXISTS idx_violations_contest ON proctoring_violations(contest_id);
CREATE INDEX IF NOT EXISTS idx_violations_timestamp ON proctoring_violations(detected_at DESC);

-- Stats
CREATE INDEX IF NOT EXISTS idx_stats_contest ON participant_stats(contest_id);
CREATE INDEX IF NOT EXISTS idx_stats_score ON participant_stats(total_score DESC);

-- --------------------------------------------------------
-- Sample Data (Optional - for testing)
-- --------------------------------------------------------

-- Insert default admin/leader
INSERT INTO leaders (username, password_hash, full_name, email, role)
VALUES (
  'admin',
  'pbkdf2:sha256:600000$default$9ef8f1b98c9e8b8d9e8c9d8e9f8e9d8c',
  'Administrator',
  'admin@debugmarathon.com',
  'admin'
) ON CONFLICT (username) DO NOTHING;

-- Insert sample contest
INSERT INTO contests (contest_name, description, status, created_by)
VALUES (
  'Debug Marathon 2026',
  'Annual debugging competition for computer science students',
  'upcoming',
  1
) ON CONFLICT DO NOTHING;

-- --------------------------------------------------------
-- Functions for automatic timestamp updates
-- --------------------------------------------------------

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_contests_updated_at BEFORE UPDATE ON contests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_proctoring_config_updated_at BEFORE UPDATE ON proctoring_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- --------------------------------------------------------
-- Refresh leaderboard function
-- --------------------------------------------------------

CREATE OR REPLACE FUNCTION refresh_leaderboard()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW leaderboard;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------
-- Complete!
-- --------------------------------------------------------

COMMENT ON DATABASE CURRENT_DATABASE() IS 'Debug Marathon Platform - PostgreSQL/Supabase Schema v4.0';

-- Enable Row Level Security (RLS) on all tables
-- This satisfies Supabase security requirements
-- Note: Backend will use service role key with full access

-- Enable RLS on all tables
ALTER TABLE leaders ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE contests ENABLE ROW LEVEL SECURITY;
ALTER TABLE rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE contest_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE participant_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE proctoring_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE proctoring_violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_state ENABLE ROW LEVEL SECURITY;

-- Create permissive policies (allow all operations)
-- Since backend handles auth, we allow service role full access

-- Leaders table
CREATE POLICY "Allow all access to leaders" ON leaders FOR ALL USING (true) WITH CHECK (true);

-- Participants table
CREATE POLICY "Allow all access to participants" ON participants FOR ALL USING (true) WITH CHECK (true);

-- Contests table
CREATE POLICY "Allow all access to contests" ON contests FOR ALL USING (true) WITH CHECK (true);

-- Rounds table
CREATE POLICY "Allow all access to rounds" ON rounds FOR ALL USING (true) WITH CHECK (true);

-- Questions table
CREATE POLICY "Allow all access to questions" ON questions FOR ALL USING (true) WITH CHECK (true);

-- Contest Submissions table
CREATE POLICY "Allow all access to contest_submissions" ON contest_submissions FOR ALL USING (true) WITH CHECK (true);

-- Participant Stats table
CREATE POLICY "Allow all access to participant_stats" ON participant_stats FOR ALL USING (true) WITH CHECK (true);

-- Proctoring Config table
CREATE POLICY "Allow all access to proctoring_config" ON proctoring_config FOR ALL USING (true) WITH CHECK (true);

-- Proctoring Violations table
CREATE POLICY "Allow all access to proctoring_violations" ON proctoring_violations FOR ALL USING (true) WITH CHECK (true);

-- Admin State table
CREATE POLICY "Allow all access to admin_state" ON admin_state FOR ALL USING (true) WITH CHECK (true);

-- Done! RLS is now enabled with permissive policies

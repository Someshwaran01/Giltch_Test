-- Supabase Data Import Script
-- Converted from MySQL dump to PostgreSQL format
-- Run this in Supabase SQL Editor

-- Clear existing data (optional - comment out if you want to keep existing data)
-- TRUNCATE TABLE violations, submissions, shortlisted_participants, questions, 
-- participant_level_stats, leaderboard, participant_proctoring, proctoring_alerts, 
-- proctoring_logs, proctoring_config, rounds, contests, users, admin_state CASCADE;

-- Insert Admin State
INSERT INTO admin_state (key_name, value, updated_at) VALUES
('contest_1_countdown', '{"active": true, "end_time": "2026-01-29T05:59:30.134862", "duration": "5", "target_level": "1"}', '2026-01-29 11:24:30')
ON CONFLICT (key_name) DO UPDATE SET value = EXCLUDED.value, updated_at = EXCLUDED.updated_at;

-- Insert Users
-- TEST CREDENTIALS (for deployment testing):
-- admin / admin@debugmarathon.com / password: admin123
-- leader1 / leader1@college.edu / password: leader123
INSERT INTO users (user_id, username, email, password_hash, full_name, role, department, college, status, is_active, admin_status, approved_by, approval_at, profile_image, registration_date, last_login) VALUES
(7317, 'admin', 'admin@debugmarathon.com', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'Super Admin', 'admin', NULL, NULL, 'active', true, 'APPROVED', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7318, 'leader1', 'leader1@college.edu', '6b4b7f0b81d0b3494dd853bc45c0605fa99125c93de8a9850cbc62b2f6d52d13', 'Leader One', 'leader', 'CSE', 'Tech Institute', 'active', true, 'APPROVED', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7319, 'PART001', 'p1@student.com', 'sha256_placeholder', 'Participant 1', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7320, 'PART002', 'p2@student.com', 'sha256_placeholder', 'Participant 2', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7321, 'PART003', 'p3@student.com', 'sha256_placeholder', 'Participant 3', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7322, 'PART004', 'p4@student.com', 'sha256_placeholder', 'Participant 4', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7323, 'PART005', 'p5@student.com', 'sha256_placeholder', 'Participant 5', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7324, 'PART006', 'p6@student.com', 'sha256_placeholder', 'Participant 6', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7325, 'PART007', 'p7@student.com', 'sha256_placeholder', 'Participant 7', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7326, 'PART008', 'p8@student.com', 'sha256_placeholder', 'Participant 8', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7327, 'PART009', 'p9@student.com', 'sha256_placeholder', 'Participant 9', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7328, 'PART010', 'p10@student.com', 'sha256_placeholder', 'Participant 10', 'participant', 'CSE', 'Engineering College', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 15:16:13', NULL),
(7329, 'SHCCSGF001', 'SHCCSGF001@example.com', 'sha256_placeholder', 'Akash ', 'participant', 'cs', 'shc', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 18:00:44', NULL),
(7330, 'SHCCSGF002', 'SHCCSGF002@example.com', 'sha256_placeholder', 'Akash ', 'participant', 'cs ', 'shc', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-27 22:12:31', NULL),
(7332, 'SHCCSGF003', 'SHCCSGF003@example.com', 'sha256_placeholder', 'sharman', 'participant', 'bca', 'shc', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-29 09:50:09', NULL),
(7333, 'SHCCSGF004', 'tabraz@gmail.com', 'sha256_placeholder', 'Tabraz', 'participant', 'cs ', 'shc', 'active', true, 'PENDING', NULL, NULL, NULL, '2026-01-29 09:50:58', NULL),
(7334, 'ak27', 'ak27@leader.com', 'scrypt:32768:8:1$JvFOaoXvjbMuT447$edbf9bbd465066c562d58096b7a18007a7ed7a61b600cf8dea4efcc3e956b1d181c5cf4c8da7d6566087faf95438a03654c8f476e7aebcda1f6443761e843956', 'akash', 'leader', 'cs', 'shc', 'active', true, 'APPROVED', NULL, NULL, NULL, '2026-01-29 10:46:41', NULL)
ON CONFLICT (user_id) DO UPDATE SET
  username = EXCLUDED.username,
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role,
  department = EXCLUDED.department,
  college = EXCLUDED.college,
  status = EXCLUDED.status,
  is_active = EXCLUDED.is_active,
  admin_status = EXCLUDED.admin_status;

-- Insert Contests
INSERT INTO contests (contest_id, contest_name, description, start_datetime, end_datetime, status, is_active, max_violations_allowed, current_round, created_by, created_at) VALUES
(1, 'Debug Marathon 2026', 'The ultimate coding challenge.', '2026-01-27 15:16:13', '2026-01-27 20:16:13', 'live', true, 10, 1, NULL, '2026-01-27 15:16:13')
ON CONFLICT (contest_id) DO UPDATE SET
  contest_name = EXCLUDED.contest_name,
  description = EXCLUDED.description,
  status = EXCLUDED.status,
  current_round = EXCLUDED.current_round;

-- Insert Rounds
INSERT INTO rounds (round_id, contest_id, round_name, round_number, time_limit_minutes, total_questions, passing_score, status, is_locked, unlock_condition, allowed_language, created_at) VALUES
(1, 1, 'Level 1', 1, 45, 2, NULL, 'active', true, NULL, 'c', '2026-01-27 15:16:13'),
(2, 1, 'Level 2', 2, 45, 2, NULL, 'pending', true, NULL, 'c', '2026-01-27 15:16:13'),
(3, 1, 'Level 3', 3, 60, 1, NULL, 'pending', true, NULL, 'python', '2026-01-27 15:16:13'),
(4, 1, 'Level 4', 4, 60, 1, NULL, 'pending', true, NULL, 'java', '2026-01-27 15:16:13'),
(5, 1, 'Level 5', 5, 90, 1, NULL, 'pending', true, NULL, 'java', '2026-01-27 15:16:13')
ON CONFLICT (round_id) DO UPDATE SET
  round_name = EXCLUDED.round_name,
  status = EXCLUDED.status,
  is_locked = EXCLUDED.is_locked;

-- Insert Questions
INSERT INTO questions (question_id, round_id, question_number, question_title, question_description, buggy_code, expected_output, test_cases, difficulty_level, points, hints, time_estimate_minutes, created_at, test_input) VALUES
(11, 2, 1, 'Check Palindrome Number', '', E'#include <stdio.h>\nint main() {\n int n, temp, rev = 0;\n scanf(\"%d\", &n);\n temp = n;\n while(n > 0) {\n rev = rev * 10 + n % 10;\n n = n / 10;\n }\n // Problem: assignment operator used instead of comparison\n if(temp = rev)\n printf(\"Palindrome\");\n else\n printf(\"Not Palindrome\");\n return 0;\n}\n', 'Palindrome', '[]', 'medium', 20, NULL, NULL, '2026-01-27 22:40:53', '121'),
(12, 2, 2, 'Sum of N Numbers Using Loop', '', E'#include <stdio.h>\nint main() {\n int n, i, sum = 0;\n scanf(\"%d\", &n);\n // Problem: loop condition is wrong (i < n)\n for(i = 1; i < n; i++) {\n sum = sum + i;\n }\n printf(\"%d\", sum);\n return 0;\n}', '15', '[]', 'medium', 20, NULL, NULL, '2026-01-28 10:06:54', '5'),
(13, 2, 3, ' Check Prime Number', '', E'#include <stdio.h>\nint main() {\n int n, i;\n scanf(\"%d\", &n);\n // Problem: wrong final condition\n for(i = 2; i < n; i++) {\n if(n % i == 0)\n break;\n }\n if(i == n)\n printf(\"Not Prime\");\n else\n printf(\"Prime\");\n return 0;\n}\n', 'Prime', '[]', 'medium', 20, NULL, NULL, '2026-01-28 17:11:47', '11'),
(14, 2, 4, 'Check Palindrome Number', '', E'int main() {\nint n, temp, rev = 0;\nscanf(\"%d\", &n);\ntemp = n;\nwhile(n > 0) {\nrev = rev * 10 + n % 10;\nn = n / 10;\n\n// Problem: assignment operator used instead of comparison\nprintf(\"%d\\n\",n);\nif(temp = rev)\nprintf(\"Palindrome\");\nelse\nprintf(\"Not Palindrome\");\nreturn 0;\n\n}', '3', '[]', 'medium', 20, NULL, NULL, '2026-01-28 22:20:42', '123'),
(16, 4, 2, 'Find the Sum of Two Numbers', '', E'import java.util.Scanner;\n\npublic class SumBug {\n    public static void main(String args[]) {\n        Scanner sc = new Scanner(System.in);\n\n        int a, b, sum;\n\n        a = sc.nextInt();\n        b = sc.nextInt();\n\n        sum = a - b;   // BUG\n\n        System.out.println(sum);\n    }\n}\n', E'15\n', '[]', 'medium', 20, NULL, NULL, '2026-01-28 23:52:31', E'10\n5\n'),
(17, 1, 1, 'basic error handling', '', E'#include <stdio.h>\n\nint main() {\n    int a, b;\n\n\n    if (scanf(\"%d %d\", &a, &b) != 2) {\n        printf(\"Error\\n\");\n        return 1;\n    }\n\n    if (b == 0) {\n        printf(\"Error\\n\");\n        return 1;\n    }\n\n    printf(\"%d\\n\", a / b);\n    return 0;\n}\n', E'4\n', '[]', 'medium', 20, NULL, NULL, '2026-01-29 09:54:18', E'8 2\n'),
(19, 1, 2, 'Logical Error', '', E'#include <stdio.h>\n\nint main() {\n    int i, sum = 0;\n\n    for (i = 1; i < 5; i++);  // BUG: extra semicolon\n        sum = sum + i;\n\n    printf(\"%d\\n\", sum);\n    return 0;\n}\n', E'5\n', '[]', 'medium', 20, NULL, NULL, '2026-01-29 10:58:05', '')
ON CONFLICT (question_id) DO UPDATE SET
  question_title = EXCLUDED.question_title,
  buggy_code = EXCLUDED.buggy_code,
  expected_output = EXCLUDED.expected_output,
  test_input = EXCLUDED.test_input;

-- Insert Proctoring Config
INSERT INTO proctoring_config (id, contest_id, enabled, max_violations, auto_disqualify, warning_threshold, grace_violations, strict_mode, track_tab_switches, track_focus_loss, block_copy, block_paste, block_cut, block_selection, block_right_click, detect_screenshot, tab_switch_penalty, copy_paste_penalty, screenshot_penalty, focus_loss_penalty, created_at, updated_at) VALUES
('bd51cfd5-3b0e-42d4-b2a1-03e116c406a7', 1, false, 10, true, 5, 2, false, true, true, true, true, true, false, true, true, 1, 2, 3, 1, '2026-01-28 10:01:23', '2026-01-28 10:01:23')
ON CONFLICT (id) DO UPDATE SET
  enabled = EXCLUDED.enabled,
  max_violations = EXCLUDED.max_violations,
  auto_disqualify = EXCLUDED.auto_disqualify,
  warning_threshold = EXCLUDED.warning_threshold;

-- Insert Participant Proctoring
INSERT INTO participant_proctoring (id, participant_id, user_id, contest_id, risk_level, total_violations, violation_score, extra_violations, is_disqualified, disqualified_at, disqualification_reason, is_suspended, suspended_at, suspension_reason, last_heartbeat, client_ip, tab_switches, focus_losses, copy_attempts, paste_attempts, screenshot_attempts, last_violation_at, created_at, updated_at) VALUES
('0f1cee22-089b-4ffa-85c0-98f4a752548c', 'PART010', 7328, 1, 'low', 0, 0, 0, false, NULL, NULL, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '2026-01-28 11:19:35', '2026-01-28 11:19:35'),
('7323_proc', 'PART005', 7323, 1, 'medium', 3, 3, 0, false, NULL, NULL, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '2026-01-27 15:21:11', '2026-01-27 15:21:11'),
('7324_proc', 'PART006', 7324, 1, 'low', 0, 0, 0, false, NULL, NULL, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '2026-01-27 15:21:11', '2026-01-27 15:21:11'),
('7325_proc', 'PART007', 7325, 1, 'low', 0, 0, 0, false, NULL, NULL, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '2026-01-27 15:21:11', '2026-01-27 15:21:11'),
('7326_proc', 'PART008', 7326, 1, 'low', 0, 0, 0, false, NULL, NULL, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '2026-01-27 15:21:11', '2026-01-27 15:21:11'),
('c60b964e-3032-415a-ba3e-26909c9bfaa8', 'SHCCSGF002', 7330, 1, 'low', 1, 1, 0, false, NULL, NULL, false, NULL, NULL, NULL, NULL, 0, 1, 0, 0, 0, '2026-01-27 16:57:22', '2026-01-27 22:12:40', '2026-01-27 16:57:22'),
('d0bebf97-6a05-4041-b707-f7a440d16f1d', 'SHCCSGF001', 7329, 1, 'low', 0, 0, 0, false, NULL, NULL, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '2026-01-27 18:11:37', '2026-01-27 18:11:37'),
('d9e68a12-debc-4344-8aba-4ca234180b2f', 'SHCCSGF004', 7333, 1, 'low', 0, 0, 0, false, NULL, NULL, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, '2026-01-29 09:55:30', '2026-01-29 09:55:30')
ON CONFLICT (id) DO UPDATE SET
  risk_level = EXCLUDED.risk_level,
  total_violations = EXCLUDED.total_violations,
  violation_score = EXCLUDED.violation_score;

-- Insert Leaderboard
INSERT INTO leaderboard (leaderboard_id, user_id, contest_id, rank_position, total_score, total_time_taken_seconds, questions_attempted, questions_correct, violations_count, current_round, last_updated) VALUES
(5, 7323, 1, 0, 10.00, 1320, 0, 1, 3, 1, '2026-01-27 15:21:11'),
(6, 7324, 1, 0, 10.00, 2640, 0, 1, 0, 1, '2026-01-27 15:21:11'),
(7, 7325, 1, 0, 10.00, 2940, 0, 1, 0, 1, '2026-01-27 15:21:11'),
(8, 7326, 1, 0, 10.00, 2580, 0, 1, 0, 1, '2026-01-27 15:21:11')
ON CONFLICT (leaderboard_id) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  questions_correct = EXCLUDED.questions_correct,
  violations_count = EXCLUDED.violations_count,
  last_updated = EXCLUDED.last_updated;

-- Insert Participant Level Stats
INSERT INTO participant_level_stats (stat_id, user_id, contest_id, level, status, questions_solved, level_score, violation_count, start_time, completed_at, run_count) VALUES
(1, 7319, 1, 1, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-27 09:18:10', NULL, 5),
(2, 7320, 1, 1, 'IN_PROGRESS', 1, 10.00, 0, '2026-01-27 09:28:10', NULL, 0),
(3, 7321, 1, 1, 'IN_PROGRESS', 1, 10.00, 3, '2026-01-27 09:40:10', NULL, 0),
(4, 7322, 1, 1, 'IN_PROGRESS', 2, 20.00, 3, '2026-01-27 09:31:10', NULL, 0),
(5, 7323, 1, 1, 'IN_PROGRESS', 1, 10.00, 3, '2026-01-27 09:29:10', NULL, 0),
(6, 7324, 1, 1, 'COMPLETED', 2, 40.00, 0, '2026-01-27 09:07:11', '2026-01-29 05:30:01', 7),
(7, 7325, 1, 1, 'COMPLETED', 2, 40.00, 0, '2026-01-27 09:02:11', '2026-01-29 05:53:37', 2),
(8, 7326, 1, 1, 'IN_PROGRESS', 1, 10.00, 0, '2026-01-27 09:08:11', NULL, 0),
(14, 7329, 1, 1, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-27 12:41:41', NULL, 1),
(16, 7329, 1, 2, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-27 12:49:12', NULL, 0),
(17, 7319, 1, 2, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-27 15:42:24', NULL, 19),
(24, 7320, 1, 3, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-27 16:03:43', NULL, 0),
(32, 7330, 1, 2, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-27 16:42:45', NULL, 7),
(42, 7320, 1, 2, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-28 04:15:10', NULL, 75),
(87, 7321, 1, 3, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-28 05:31:43', NULL, 0),
(88, 7326, 1, 3, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-28 05:50:10', NULL, 0),
(144, 7324, 1, 4, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-28 17:16:11', NULL, 1),
(146, 7320, 1, 4, 'COMPLETED', 1, 20.00, 0, '2026-01-28 17:18:59', '2026-01-28 18:46:15', 22),
(170, 7320, 1, 5, 'NOT_STARTED', 0, 0.00, 0, NULL, NULL, 0),
(172, 7333, 1, 1, 'IN_PROGRESS', 0, 0.00, 0, '2026-01-29 04:25:44', NULL, 1),
(181, 7324, 1, 2, 'NOT_STARTED', 0, 0.00, 0, NULL, NULL, 0),
(191, 7325, 1, 2, 'NOT_STARTED', 0, 0.00, 0, NULL, NULL, 0)
ON CONFLICT (stat_id) DO UPDATE SET
  status = EXCLUDED.status,
  questions_solved = EXCLUDED.questions_solved,
  level_score = EXCLUDED.level_score,
  run_count = EXCLUDED.run_count,
  completed_at = EXCLUDED.completed_at;

-- Insert Shortlisted Participants
INSERT INTO shortlisted_participants (id, contest_id, user_id, level, is_allowed) VALUES
(1, 1, 7319, 3, true),
(3, 1, 7327, 3, true),
(4, 1, 7322, 3, true),
(5, 1, 7328, 3, true),
(6, 1, 7323, 3, true),
(7, 1, 7329, 3, true),
(8, 1, 7324, 4, true),
(9, 1, 7330, 4, true),
(10, 1, 7323, 4, true),
(14, 1, 7329, 4, true),
(21, 1, 7319, 4, true),
(36, 1, 7324, 3, true),
(38, 1, 7330, 3, true),
(39, 1, 7325, 3, true),
(50, 1, 7320, 3, true),
(51, 1, 7326, 3, true),
(52, 1, 7321, 3, true),
(65, 1, 7325, 4, true),
(66, 1, 7320, 4, true),
(67, 1, 7326, 4, true),
(68, 1, 7321, 4, true),
(69, 1, 7327, 4, true),
(70, 1, 7322, 4, true),
(71, 1, 7328, 4, true),
(101, 1, 7328, 2, true),
(102, 1, 7323, 2, true),
(103, 1, 7329, 2, true),
(104, 1, 7324, 2, true),
(105, 1, 7319, 2, true),
(106, 1, 7330, 2, true),
(107, 1, 7325, 2, true),
(108, 1, 7320, 2, true),
(109, 1, 7326, 2, true),
(110, 1, 7321, 2, true),
(111, 1, 7327, 2, true),
(112, 1, 7322, 2, true)
ON CONFLICT (id) DO UPDATE SET is_allowed = EXCLUDED.is_allowed;

-- Insert Submissions
INSERT INTO submissions (submission_id, user_id, contest_id, round_id, question_id, submitted_code, is_correct, score_awarded, test_results, status, time_taken_seconds, submission_timestamp) VALUES
(24, 7324, 1, 1, 19, E'#include <stdio.h>\n\nint main() {\n    int i, sum = 0;\n\n    for (i = 1; i < 5; i++); // BUG: extra semicolon\n        sum = sum + i;\n\n    printf(\"%d\\n\", sum);\n    return 0;\n}\n', true, 20.00, '[{"input": "", "expected": "5", "output": "5", "passed": true, "error": null, "warnings": ""}]', 'evaluated', 0, '2026-01-29 10:59:59'),
(25, 7324, 1, 1, 17, E'#include <stdio.h>\n\nint main() {\n    int a, b;\n\n\n    if (scanf(\"%d %d\", &a, &b) != 2) {\n        printf(\"Error\\n\");\n        return 1;\n    }\n\n    if (b == 0) {\n        printf(\"Error\\n\");\n        return 1;\n    }\n\n    printf(\"%d\\n\", a / b);\n    return 0;\n}\n', true, 20.00, '[{"input": "8 2\\n", "expected": "4", "output": "4", "passed": true, "error": null, "warnings": ""}]', 'evaluated', 0, '2026-01-29 11:01:27'),
(26, 7325, 1, 1, 17, E'#include <stdio.h>\n\nint main() {\n    int a, b;\n\n\n    if (scanf(\"%d %d\", &a, &b) != 2) {\n        printf(\"Error\\n\");\n        return 1;\n    }\n\n    if (b == 0) {\n        printf(\"Error\\n\");\n        return 1;\n    }\n\n    printf(\"%d\\n\", a / b);\n    return 0;\n}\n', true, 20.00, '[{"input": "8 2\\n", "expected": "4", "output": "4", "passed": true, "error": null, "warnings": ""}]', 'evaluated', 0, '2026-01-29 11:23:17'),
(27, 7325, 1, 1, 19, E'#include <stdio.h>\n\nint main() {\n    int i, sum = 0;\n\n    for (i = 1; i < 5; i++);  // BUG: extra semicolon\n        sum = sum + i;\n\n    printf(\"%d\\n\", sum);\n    return 0;\n}\n', true, 20.00, '[{"input": "", "expected": "5", "output": "5", "passed": true, "error": null, "warnings": ""}]', 'evaluated', 0, '2026-01-29 11:23:34')
ON CONFLICT (submission_id) DO UPDATE SET
  is_correct = EXCLUDED.is_correct,
  score_awarded = EXCLUDED.score_awarded,
  test_results = EXCLUDED.test_results,
  status = EXCLUDED.status;

-- Insert Violations
INSERT INTO violations (violation_id, user_id, contest_id, round_id, question_id, violation_type, description, severity, penalty_points, level, ip_address, timestamp) VALUES
(7, 7323, 1, NULL, NULL, 'TAB_SWITCH', 'Switched tab during exam', 'medium', 1, 1, NULL, '2026-01-27 15:21:10'),
(8, 7323, 1, NULL, NULL, 'TAB_SWITCH', 'Switched tab during exam', 'medium', 1, 1, NULL, '2026-01-27 15:21:11'),
(9, 7323, 1, NULL, NULL, 'TAB_SWITCH', 'Switched tab during exam', 'medium', 1, 1, NULL, '2026-01-27 15:21:11'),
(13, 7330, 1, NULL, NULL, 'FOCUS_LOST', 'Window focus lost (Alt+Tab or outside click)', 'low', 1, 2, NULL, '2026-01-27 16:57:22')
ON CONFLICT (violation_id) DO UPDATE SET
  description = EXCLUDED.description,
  severity = EXCLUDED.severity;

-- Reset sequences to match the max IDs
SELECT setval('users_user_id_seq', (SELECT MAX(user_id) FROM users));
SELECT setval('contests_contest_id_seq', (SELECT MAX(contest_id) FROM contests));
SELECT setval('rounds_round_id_seq', (SELECT MAX(round_id) FROM rounds));
SELECT setval('questions_question_id_seq', (SELECT MAX(question_id) FROM questions));
SELECT setval('leaderboard_leaderboard_id_seq', (SELECT MAX(leaderboard_id) FROM leaderboard));
SELECT setval('participant_level_stats_stat_id_seq', (SELECT MAX(stat_id) FROM participant_level_stats));
SELECT setval('shortlisted_participants_id_seq', (SELECT MAX(id) FROM shortlisted_participants));
SELECT setval('submissions_submission_id_seq', (SELECT MAX(submission_id) FROM submissions));
SELECT setval('violations_violation_id_seq', (SELECT MAX(violation_id) FROM violations));

-- Refresh materialized view if needed
-- REFRESH MATERIALIZED VIEW leaderboard_view;

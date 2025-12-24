-- 1. Clean up old data
DROP TABLE IF EXISTS acceptance_stats;
DROP TABLE IF EXISTS problems;

-- 2. Create problems table (with is_paid)
CREATE TABLE problems (
    id              INT PRIMARY KEY,              -- LeetCode frontend_question_id
    slug            TEXT UNIQUE NOT NULL,         -- question__title_slug
    title           TEXT NOT NULL,                -- question__title
    difficulty      INT,                          -- 1: Easy, 2: Medium, 3: Hard
    is_paid         BOOLEAN DEFAULT FALSE,        -- Whether the problem is paid-only
    first_synced_at TIMESTAMPTZ DEFAULT NOW(),
    last_synced_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create acceptance_stats table
CREATE TABLE acceptance_stats (
    id              BIGSERIAL PRIMARY KEY,
    problem_id      INT REFERENCES problems(id) ON DELETE CASCADE,
    total_accepted  BIGINT,
    total_submitted BIGINT,
    collected_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create function to auto-update last_synced_at (and protect first_synced_at)
CREATE OR REPLACE FUNCTION update_last_synced_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.last_synced_at = NOW();
   NEW.first_synced_at = OLD.first_synced_at; -- 強制保留初始同步時間
   RETURN NEW;
END;
$$ language 'plpgsql';

-- 5. Create trigger
CREATE TRIGGER tr_update_problems_sync_time
BEFORE UPDATE ON problems
FOR EACH ROW
EXECUTE PROCEDURE update_last_synced_at_column();

-- 6. Create index
CREATE INDEX idx_stats_problem_id_time ON acceptance_stats(problem_id, collected_at DESC);

-- 7. Disable RLS
ALTER TABLE problems DISABLE ROW LEVEL SECURITY;
ALTER TABLE acceptance_stats DISABLE ROW LEVEL SECURITY;
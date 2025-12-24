-- 1. Ensure pg_cron extension is enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Create data cleanup function
CREATE OR REPLACE FUNCTION clean_old_acceptance_stats()
RETURNS void AS $$
BEGIN
  DELETE FROM acceptance_stats
  WHERE NOT (
    -- Keep records from the last 30 days
    collected_at > NOW() - INTERVAL '30 days'
    OR 
    -- Keep records for the 1st day of each month within the last 24 months
    (
      EXTRACT(DAY FROM collected_at) = 1 
      AND collected_at > NOW() - INTERVAL '24 months'
    )
  );
END;
$$ LANGUAGE plpgsql;

-- 3. Schedule the cleanup task (run daily at 1 AM)
-- Use cron.unschedule to avoid duplicate task names
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup-stats-task') THEN
        PERFORM cron.unschedule('cleanup-stats-task');
    END IF;
END $$;

-- 重新建立排程
SELECT cron.schedule(
  'cleanup-stats-task',
  '0 1 * * *',
  'SELECT clean_old_acceptance_stats();'
);
# LeetCode Status

This is an automation tool designed to fetch the LeetCode problem list and acceptance statistics daily, and store them in a Supabase database (Free Tier optimized). With Grafana, you can easily visualize the difficulty and acceptance rate trends of each problem over time.

## Features

* Automatic sync: Triggered daily via GitHub Actions.
* Complete data: Records problem ID, slug, title, difficulty, paid status, and detailed submission statistics.
* Smart updates: Database triggers automatically manage timestamps.
* Performance optimized: Edge Function uses batching (500 records/batch) to reliably process 3000+ records without memory issues.
* Data Retention: Built-in lifecycle management using pg_cron to keep the database footprint small.

## SQL Table Structure Logic

This project contains two main tables:
1. `problems`

Stores problem metadata. The id uses LeetCode's `frontend_question_id` (the number shown on the website).
    * Auto-protection: A PostgreSQL trigger ensures `first_synced_at` is only set on initial insert and not overwritten on upsert.
    * Auto-update: Whenever problem info changes, `last_synced_at` is automatically updated to the current time.
    & Paid Status: Includes is_paid (boolean) to filter premium-only content.

2. `acceptance_stats`

Time-series table for Grafana tracking.
    * Snapshot: A new record is added for every problem daily.

    * Index: A composite index `(problem_id, collected_at DESC)` ensures high-speed queries for trend charts.

3. Data Retention Policy (Life Cycle)

To stay within Supabase Free Tier limits, a pg_cron job runs daily at 01:00 AM:

    * Full Detail: Keeps all records for the last 30 days.

    * Historical Trend: Keeps records from the 1st day of each month for the last 24 months.

    * Cleanup: Automatically deletes all other intermediate historical data.

## Local Development & Testing

Before deploying to the cloud, you can simulate execution locally:
1. Environment Preparation

Make sure you have installed the Supabase CLI.
```bash
supabase login
supabase link --project-ref [ProjectID]

# Keep your local migration history in sync
supabase db pull
```
2. Set Environment Variables

Create a `.env` file under the `supabase/` directory:
```bash
SUPABASE_URL=your_project_url
SUPABASE_SERVICE_ROLE_KEY=yourServiceRoleKey
```

3. Start Local Testing

Run the following command to start the Edge Function local server:
```bash
supabase functions serve sync-leetcode --env-file ./supabase/.env
```

Then, you can use curl or Postman to send a POST request to http://localhost:54321/functions/v1/sync-leetcode for testing.

## Deployment Commands
1. Database Migrations

    Always use the CLI to push schema changes to ensure the migration history is tracked.
```bash
# Push new migration files (e.g., data retention scripts)
supabase db push


# If remote and local history conflict, use repair (with caution):
# supabase migration repair [Version] --status applied
```
2. Edge Function Deployment
```bash
supabase functions deploy sync-leetcode
```


## GitHub Actions Setup

Automated sync relies on scheduled GitHub Actions.
Required Secrets:

Go to GitHub Repo Settings > Secrets and variables > Actions and add the following Secret:

* `SUPABASE_SERVICE_ROLE_KEY`:

    * Source: Supabase Dashboard > Settings > API > `service_role` (secret).

    * Purpose: Allows GitHub to call the Edge Function and bypass RLS for write permissions.

* Note: The Project ID is hardcoded in the daily_sync.yml URL, so no extra Secret is needed for it.

## Notes

    LeetCode API source: https://leetcode.com/api/problems/all/
    It is recommended to use Grafana's PostgreSQL Data Source for visualization with this project.
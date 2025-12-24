# LeetCode Status

This is an automation tool designed to fetch the LeetCode problem list and acceptance statistics daily, and store them in a Supabase database (in free tier). With Grafana, you can easily visualize the difficulty and acceptance rate trends of each problem over time.

## Features

* Automatic sync: Triggered daily via GitHub Actions.
* Complete data: Records problem ID, slug, title, difficulty, paid status, and detailed submission statistics.
* Smart updates: Database triggers automatically manage timestamps.
* Performance optimized: Edge Function uses batching to reliably process 3000+ records.

## SQL Table Structure Logic

This project contains two main tables:
1. problems

Stores problem metadata. The id uses LeetCode's frontend_question_id (the number shown on the website).
    * Auto-protection: A PostgreSQL trigger ensures first_synced_at is only set on initial insert and not overwritten on upsert.
    * Auto-update: Whenever problem info changes, last_synced_at is automatically updated to the current time.

2. acceptance_stats

Time-series table for Grafana.
    * A new record is added for each problem every day.
    * A composite index (problem_id, collected_at DESC) ensures query performance with large datasets.

## Local Development & Testing

Before deploying to the cloud, you can simulate execution locally:
1. Environment Preparation

Make sure you have installed the Supabase CLI.
2. Set Environment Variables

Create a .env file under the supabase/ directory (this file is in .gitignore):
```
SUPABASE_URL=your_project_url
SUPABASE_SERVICE_ROLE_KEY=yourServiceRoleKey
```

3. Start Local Testing

Run the following command to start the Edge Function local server:
```bash
supabase functions serve sync-leetcode --env-file ./supabase/.env
```

Then, you can use curl or Postman to send a POST request to http://localhost:54321/functions/v1/sync-leetcode for testing.

## GitHub Actions Setup

Automated sync relies on scheduled GitHub Actions.
Required Secrets:

Go to GitHub Repo Settings > Secrets and variables > Actions and add the following Secret:

    SUPABASE_SERVICE_ROLE_KEY:

        Source: Supabase Dashboard > Settings > API > service_role (secret).

        Purpose: Allows GitHub to call the Edge Function and bypass RLS for write permissions.

    Note: The Project ID is hardcoded in the daily_sync.yml URL, so no extra Secret is needed for it.

## Deployment Command

After modifying index.ts, use the following command to deploy it to the cloud:
```bash
supabase functions deploy sync-leetcode
```

After deployment, make sure to enable "Enforce JWT Authorization" for the Function in the Supabase Dashboard (or ensure your GitHub Action YAML includes the correct Authorization Header).

## Notes

    LeetCode API source: https://leetcode.com/api/problems/all/
    It is recommended to use Grafana's PostgreSQL Data Source for visualization with this project.
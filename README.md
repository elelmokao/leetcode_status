# LeetCode Status

This is an SaaS-based tool fetching LeetCode problems and submission/acceptance to be stored in a Supabase Free Tier database. Integrating with Grafana, the trends of Leetcode problems over time can be visualized. The API given to provide the metadata of problem.

## Supabase

As the backend of storing Leetcode metadata and statistics. It provides datasources for Grafana and also the API when retrieving metadata of problem through problem ID.

### Features

* **Automatic sync**: Daily syncing via GitHub Actions.

* **Complete data**: Records problem ID, slug, title, difficulty, paid status, submission, and acceptance.

* **Performance optimized**: Edge Function uses batching to process 3000+ records.

* **Data Retention**: Built-in lifecycle management using `pg_cron` to keep the database footprint small.

* **RPC Function**: Simplifies querying the metadata for each problem through `frontend_question_id`.

### SQL Table Structure Logic

This project contains two main tables:
#### 1. problems

Stores problem metadata. The id uses LeetCode's `frontend_question_id` (the number shown on the website).

| column_name     | data_type                | remarks                     |
| --------------- | ------------------------ | --------------------------- |
| id              | integer                  | frontend_question_id        |
| difficulty      | integer                  | 1: easy; 2: medium; 3: hard |
| is_paid         | boolean                  |                             |
| slug            | text                     |                             |
| title           | text                     |                             |
| first_synced_at | timestamp with time zone |                             |
| last_synced_at  | timestamp with time zone |                             |

#### 2. acceptance_stats

A time series database (TSDB) for tracking submissions & acceptance.

* Snapshot: A new record is added for every problem daily.

* Index: A composite index `(problem_id, collected_at DESC)` ensures high-speed queries for trend charts.

| column_name     | data_type                | remarks                     |
| --------------- | ------------------------ | --------------------------- |
| id              | bigint                   |                             |
| problem_id      | integer                  | -> `problems.id`            |
| total_accepted  | bigint                   |                             |
| total_submitted | bigint                   |                             |
| collected_at    | timestamp with time zone |                             |

### Data Retention

To keep the database inside free tier, the data retention is set:
* Daily - lastest 30 days of records updated at 0 a.m. UTC (time might varies depending on Github Action).
* Monthly - lastest 2 years of records at first day of each month.

### RPC Function

The RPC Function is built to enable querying problem metadata. For example:
```
curl -X POST 'https://your-project.supabase.co/rest/v1/rpc/get_problem_metadata' \
-H "apikey: YOUR_ANON_KEY" \
-H "Authorization: Bearer YOUR_ANON_KEY" \
-d '{"input_id": 1}'
```

## Grafana Visualization

A Grafana dashboard for visualizing submission & acceptance.

### Features

* **IaC Management**: Built with Terraform, tracks dashboard changes easily.

* **Auto Deployment**: Once files under `grafana/` is changed, auto deployment will happen.

## To-do

- [ ] More smoothly transit Grafana manual dashboard to the auto-deployed dashboard, and publish it in public (also shown on `README.md`).
- [ ] Add setup section in README

## Notes

LeetCode API source: https://leetcode.com/api/problems/all/.
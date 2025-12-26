resource "grafana_data_source" "supabase" {
  type = "postgres"
  name = "Supabase_LeetCode"
  url  = "aws-1-ap-south-1.pooler.supabase.com:6543"
  database_name = "postgres"
  username      = "postgres.raggfqikonlermdpkjcb"
  
  secure_json_data_encoded = jsonencode({
    password = var.db_password
  })

  json_data_encoded = jsonencode({
    sslmode          = "require"
    postgresVersion  = 1500
    timescaledb      = false
  })
}

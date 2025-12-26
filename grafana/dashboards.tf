resource "grafana_dashboard" "leetcode_status" {
  config_json = templatefile("${path.module}/dashboards/leetcode_main.json", {
    DS_POSTGRES = grafana_data_source.supabase.uid
  })
}
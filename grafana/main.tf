terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = "~>4.0"
    }
  }
}

provider "grafana" {
  url   = "https://elelmokao.grafana.net"
  auth  = var.grafana_token
}

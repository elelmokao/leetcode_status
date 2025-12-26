terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "elelmokao_project"

    workspaces {
      name = "grafana_autodeploy"
    }
  }
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

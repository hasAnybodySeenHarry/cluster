locals {
  argocd_apps = {
    for app in var.argocd_apps : app.app-name => app
  }

  github_oauth = "github-oauth-secret"

  loki_namespace = "monitoring"
  loki_chart     = "loki-stack"
}
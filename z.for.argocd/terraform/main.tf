locals {
  argocd_apps = {
    for app in var.argocd_apps : app.app-name => app
  }

  github_oauth = "github-oauth-secret"
}
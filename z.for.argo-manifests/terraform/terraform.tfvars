argocd_apps = [
  {
    app-name        = "prod-apps",
    repository-url  = "https://github.com/hasAnybodySeenHarry/cluster",
    target-revision = "HEAD",
    source-path     = "prod"
    server-url      = "https://kubernetes.default.svc"
  },
]

oidc_client_id     = "value"
oidc_client_secret = "value"
server_url         = "value"
argocd_apps = [
  {
    app-name        = "dev-apps",
    repository-url  = "https://github.com/hasAnybodySeenHarry/cluster",
    target-revision = "HEAD",
    source-path     = "z.for.killerconda"
    server-url      = "https://kubernetes.default.svc"
  },
]
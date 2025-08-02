argocd_apps = [
  {
    app-name        = "throttler",
    repository-url  = "https://github.com/hasAnybodySeenHarry/cluster",
    target-revision = "HEAD",
    source-path     = "z.for.argocd/app",
    server-url      = "https://kubernetes.default.svc"
  },
]
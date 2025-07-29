argocd_apps = [
  {
    app-name        = "throttler",
    repository-url  = "https://github.com/hasAnybodySeenHarry/cluster",
    target-revision = "HEAD",
    source-path     = "z.for.mesh-lab/app",
    server-url      = "https://kubernetes.default.svc"
  },
]

inject_mesh = true
argocd_apps = [
  {
    app-name        = "dev-apps",
    repository-url  = "https://github.com/hasAnybodySeenHarry/cluster",
    target-revision = "HEAD",
    source-path     = "z.for.mesh-lab"
    server-url      = "https://kubernetes.default.svc"
  },
]

inject_mesh = true
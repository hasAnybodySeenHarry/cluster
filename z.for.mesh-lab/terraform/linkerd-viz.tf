resource "helm_release" "linkerd_viz" {
  name             = "linkerd-viz"
  namespace        = "linkerd-viz"
  repository       = "https://helm.linkerd.io/edge"
  chart            = "linkerd-viz"
  version          = "2025.8.1"
  create_namespace = true

  atomic = true

  values = [
    <<-EOT
      linkerdVersion: "edge-25.8.1"
      tapInjector:
        replicas: 0
      dashboard:
        replicas: 0
      tap:
        replicas: 0
    EOT
  ]

  depends_on = [ 
    helm_release.linkerd 
  ]
}
resource "helm_release" "linkerd" {
  name             = "linkerd-viz"
  namespace        = helm_release.linkerd_crds.namespace
  repository       = "https://helm.linkerd.io/stable"
  chart            = "linkerd-viz"
  version          = "v30.12.11"
  create_namespace = false

  atomic = true

  values = [ 
    <<-EOT
      linkerdVersion: edge-2025.7.4
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
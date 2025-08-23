resource "helm_release" "linkerd_crds" {
  namespace        = "linkerd"
  create_namespace = true

  name    = "linkerd-crds"
  chart   = "linkerd-crds"
  version = "2025.7.4"

  repository = "https://helm.linkerd.io/edge"

  atomic = true
}
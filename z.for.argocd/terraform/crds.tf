resource "helm_release" "prometheus_crds" {
  namespace        = "prometheus"
  create_namespace = true

  name    = "prometheus-operator-crds"
  chart   = "prometheus-operator-crds"
  version = "v22.0.1"

  repository = "https://prometheus-community.github.io/helm-charts"

  atomic = true
}

resource "helm_release" "linkerd_crds" {
  namespace        = "linkerd"
  create_namespace = true

  name    = "linkerd-crds"
  chart   = "linkerd-crds"
  version = "2025.7.4"

  repository = "https://helm.linkerd.io/edge"

  atomic = true
}
resource "helm_release" "prometheus_crds" {
  namespace        = "monitoring"
  create_namespace = true

  name    = "prometheus-operator-crds"
  chart   = "prometheus-operator-crds"
  version = "v22.0.1"

  repository = "https://prometheus-community.github.io/helm-charts"

  atomic = true
}
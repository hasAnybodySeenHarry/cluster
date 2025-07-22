resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.prometheus_version
  create_namespace = true

  dynamic "set" {
    for_each = var.inject_mesh ? [
      {
        key   = "prometheus.prometheusSpec.podMetadata.annotations.linkerd\\.io/inject",
        value = "enabled"
      }
    ] : []

    content {
      name  = set.value.key
      value = set.value.value
    }
  }

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}
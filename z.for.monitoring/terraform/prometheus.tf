resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "v62.3.1"
  create_namespace = true

  set = concat(
    [
      {
        name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
        value = "false"
      }
    ],
    // conditionally add this if var.inject_mesh is true
    var.inject_mesh ? [
      {
        name  = "prometheus.prometheusSpec.podMetadata.annotations.linkerd\\.io/inject"
        value = "enabled"
      }
    ] : []
  )
}
resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  create_namespace = true

  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "v76.3.0"

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

  values = [
    <<-EOT
      grafana:
        enabled: false
      alertmanager:
        enabled: true
      kubeStateMetrics:
        enabled: true
      nodeExporter:
        enabled: true
    EOT
  ]
}
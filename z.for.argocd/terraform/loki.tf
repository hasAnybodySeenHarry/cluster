resource "helm_release" "loki_stack" {
  namespace        = local.loki_namespace
  create_namespace = false

  name    = "loki"
  chart   = local.loki_chart
  version = var.chart_version

  repository = "https://grafana.github.io/helm-charts"

    values = [
      <<-YAML
        grafana:
          enabled: true
      YAML
    ]

  depends_on = [
    helm_release.prometheus_crds
  ]
}
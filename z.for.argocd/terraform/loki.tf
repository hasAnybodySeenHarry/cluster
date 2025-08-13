resource "helm_release" "loki_stack" {
  namespace        = "monitoring"
  create_namespace = false

  name    = "loki"
  chart   = "loki-stack"
  version = "v2.10.2"

  repository = "https://grafana.github.io/helm-charts"

  #   values = [
  #     <<-YAML

  #     YAML
  #   ]
  depends_on = [
    helm_release.prometheus_crds
  ]
}
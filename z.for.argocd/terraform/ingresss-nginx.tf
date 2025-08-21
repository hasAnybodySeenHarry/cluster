resource "helm_release" "nginx" {
  count = 1

  namespace        = "ingress-nginx"
  create_namespace = true

  name  = "ingress-nginx"
  chart = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = "v4.13.0"

  values = [
    <<-YAML
    controller:
      service:
        type: "ClusterIP"
      podAnnotations:
        linkerd.io/inject: "enabled"
      admissionWebhooks:
        enabled: false
    YAML
  ]

  depends_on = [
    helm_release.linkerd
  ]
}
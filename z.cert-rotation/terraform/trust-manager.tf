resource "helm_release" "trust_manager" {
  namespace        = helm_release.cert_manager.namespace
  create_namespace = false

  name       = "trust-manager"
  chart      = "trust-manager"
  repository = "https://charts.jetstack.io"
  version    = "v0.18.0"

  wait   = true
  atomic = true

  set {
    name  = "app.trust.namespace"
    value = local.cert_manager_ns
  }

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "trust_bundle" {
  yaml_body = file("${path.module}/certificates/trust_bundle.yaml")

  depends_on = [
    kubectl_manifest.linkerd_trust_anchor,
    null_resource.linkerd_previous_anchor,
    helm_release.trust_manager
  ]
}
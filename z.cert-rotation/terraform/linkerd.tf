resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = "linkerd"
  }
}

resource "helm_release" "cert_manager" {
  namespace        = "cert-manager"
  create_namespace = true

  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.18.2"

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

resource "helm_release" "trust-manager" {
  namespace        = "cert-manager"
  create_namespace = false

  name       = "trust-manager"
  chart      = "trust-manager"
  repository = "https://charts.jetstack.io"
  version    = "v0.18.0"

  wait = true

  set {
    name  = "app.trust.namespace"
    value = "cert-manager"
  }

  depends_on = [
    helm_release.cert_manager
  ]
}


locals {
  linkerd_ns      = "linkerd"
  cert_manager_ns = "cert-manager"
}

resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = local.linkerd_ns
  }
}

resource "helm_release" "cert_manager" {
  namespace        = local.cert_manager_ns
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
  namespace        = local.cert_manager_ns
  create_namespace = false

  name       = "trust-manager"
  chart      = "trust-manager"
  repository = "https://charts.jetstack.io"
  version    = "v0.18.0"

  wait = true

  set {
    name  = "app.trust.namespace"
    value = local.cert_manager_ns
  }

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubernetes_role" "cert-manager-secret-creator" {
  metadata {
    name      = "cert-manager-secret-creator"
    namespace = local.linkerd_ns
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "cert-manager-secret-creator-binding" {
  metadata {
    name = "cert-manager-secret-creator-binding"
    namespace = local.linkerd_ns
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "cert-manager-secret-creator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cert-manager"
    namespace = local.cert_manager_ns
  }
}
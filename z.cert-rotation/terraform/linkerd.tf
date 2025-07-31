locals {
  linkerd_ns      = "linkerd"
  cert_manager_ns = "cert-manager"
}

resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = local.linkerd_ns
  }
}

resource "kubernetes_role" "cert_manager_secret_creator" {
  metadata {
    name      = "cert-manager-secret-creator"
    namespace = local.linkerd_ns
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get", "update", "patch"]
  }

  depends_on = [ 
    kubernetes_namespace.linkerd 
  ]
}

resource "kubernetes_role_binding" "cert_manager_secret_creator_binding" {
  metadata {
    name      = "cert-manager-secret-creator-binding"
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

  depends_on = [ 
    kubernetes_namespace.linkerd 
  ]
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

  depends_on = [ 
    kubernetes_namespace.linkerd
  ]
}

resource "helm_release" "trust_manager" {
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

resource "kubectl_manifest" "linkerd_trust_root_issuer" {
  yaml_body = file("${path.module}/certificates/trust_root_issuer.yaml")

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "linkerd_trust_anchor" {
  yaml_body = file("${path.module}/certificates/trust_anchor.yaml")

  depends_on = [
    kubectl_manifest.linkerd_trust_root_issuer
  ]
}

resource "kubectl_manifest" "linkerd_identity_issuer_issuer" {
  yaml_body = file("${path.module}/certificates/identity_issuer_issuer.yaml")

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "linkerd_identity_issuer" {
  yaml_body = file("${path.module}/certificates/identity_issuer.yaml")

  depends_on = [
    kubectl_manifest.linkerd_identity_issuer_issuer
  ]
}
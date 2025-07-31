resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = local.linkerd_ns
    labels = {
      "linkerd.io/is-control-plane" = "true"
    }
  }
}

resource "helm_release" "linkerd_crds" {
  namespace        = local.linkerd_ns
  create_namespace = false

  name    = "linkerd-crds"
  chart   = "linkerd-crds"
  version = "2025.7.4"

  repository = "https://helm.linkerd.io/edge"

  atomic = true

  depends_on = [
    kubectl_manifest.trust_bundle
  ]
}

resource "helm_release" "linkerd" {
  name             = "linkerd-control-plane"
  namespace        = helm_release.linkerd_crds.namespace
  repository       = "https://helm.linkerd.io/edge"
  chart            = "linkerd-control-plane"
  version          = "2025.7.4"
  create_namespace = false

  atomic = true

  set {
    name  = "identity.externalCA"
    value = true
  }

  set {
    name  = "identity.issuer.scheme"
    value = "kubernetes.io/tls"
  }

  set {
    name  = "proxy.logLevel"
    value = "error"
  }

  set {
    name  = "proxy.nativeSidecar"
    value = false
  }

  set {
    name  = "proxy.enableShutdownEndpoint"
    value = false
  }

  depends_on = [
    helm_release.linkerd_crds
  ]
}

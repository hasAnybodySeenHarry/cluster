resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem       = tls_private_key.ca.private_key_pem
  is_ca_certificate     = true
  set_subject_key_id    = true
  validity_period_hours = 87600
  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
  subject {
    common_name = "root.linkerd.cluster.local"
  }
}

resource "tls_private_key" "issuer" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "issuer" {
  private_key_pem = tls_private_key.issuer.private_key_pem
  subject {
    common_name = "identity.linkerd.cluster.local"
  }
}

resource "tls_locally_signed_cert" "issuer" {
  cert_request_pem      = tls_cert_request.issuer.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  is_ca_certificate     = true
  set_subject_key_id    = true
  validity_period_hours = 8760
  allowed_uses = [
    "cert_signing",
    "crl_signing"
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
    name  = "identityTrustAnchorsPEM"
    value = tls_locally_signed_cert.issuer.ca_cert_pem
  }

  set {
    name  = "identity.issuer.tls.crtPEM"
    value = tls_locally_signed_cert.issuer.cert_pem
  }

  set {
    name  = "identity.issuer.tls.keyPEM"
    value = tls_private_key.issuer.private_key_pem
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
    value = true
  }

  depends_on = [
    helm_release.linkerd_crds
  ]
}

resource "helm_release" "linkerd_crds" {
  namespace        = "linkerd"
  create_namespace = true

  name    = "linkerd-crds"
  chart   = "linkerd-crds"
  version = "2025.7.4"

  repository = "https://helm.linkerd.io/edge"

  atomic = true
}
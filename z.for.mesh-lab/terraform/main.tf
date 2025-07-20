terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubectl" {
  load_config_file = true
  config_path      = "~/.kube/config"
}

locals {
  argocd_apps = {
    for app in var.argocd_apps : app.app-name => app
  }
}

// linkerd helm release
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
  repository       = "https://helm.linkerd.io/stable"
  chart            = "linkerd-control-plane"
  version          = "1.16.11"
  create_namespace = false

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

  # set {
  #   name  = "proxy.logLevel"
  #   value = "debug,linkerd=debug,trust_dns=error"
  # }

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
}

// argocd helm release
resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true

  name  = "argocd"
  chart = "argo-cd"

  repository = "https://argoproj.github.io/argo-helm"

  depends_on = [
    helm_release.linkerd
  ]
}

resource "kubectl_manifest" "argocd_applications" {
  for_each = local.argocd_apps

  yaml_body = templatefile("${path.module}/application.yaml.tmpl", {
    app-name        = each.value.app-name
    repository-url  = each.value.repository-url
    target-revision = each.value.target-revision
    source-path     = each.value.source-path
    server-url      = each.value.server-url
  })

  depends_on = [
    helm_release.argocd
  ]
}
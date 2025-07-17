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
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubectl" {
  load_config_file = true
  config_path = "~/.kube/config"
}

locals {
  argocd_apps = {
    for app in var.argocd_apps : app.app-name => app
  }
}

// nginx helm release
resource "helm_release" "nginx" {
  namespace = "ingress-nginx"
  create_namespace = true

  name = "ingress-nginx"
  chart = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"

  values = [
    yamlencode({
      controller = {
        allowSnippetAnnotations = "true"
        service = {
          type = "NodePort"
        }
        podAnnotations = {
          "linkerd.io/inject" = "enabled"
        }
        config = {
          annotations-risk-level = "Critical"
        }
      }
    })
  ]
}

// argocd helm release
resource "helm_release" "argocd" {
  namespace = "argocd"
  create_namespace = true

  name = "argocd"
  chart = "argo-cd"

  repository = "https://argoproj.github.io/argo-helm"
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
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16.1"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
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
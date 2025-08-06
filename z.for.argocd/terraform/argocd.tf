resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_secret_v1" "github_oauth" {
  metadata {
    name      = local.github_oauth
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  type = "Opaque"

  data = {
    "clientSecret" = var.oidc_client_secret
  }

  depends_on = [
    kubernetes_namespace_v1.argocd
  ]
}

resource "helm_release" "argocd" {
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  create_namespace = false

  name       = "argocd"
  chart      = "argo-cd"
  version    = "v8.2.5"
  repository = "https://argoproj.github.io/argo-helm"

  atomic = true
  wait   = true

  values = [
    <<-EOT
      configs:
        params:
          server.insecure: true
        cm:
          admin.enabled: false
          url: ${var.server_url}
          dex.config: |
            connectors:
            - type: github
              id: github
              name: GitHub
              config:
                clientID: ${var.oidc_client_id}
                clientSecret: $github-oauth-secret:clientSecret
        rbac:
          policy.default: "role:admin"
    EOT
  ]

  depends_on = [
    kubernetes_secret_v1.github_oauth,
    helm_release.argo_rollouts
  ]
}

resource "kubectl_manifest" "argocd_applications" {
  for_each = local.argocd_apps

  yaml_body = templatefile("${path.module}/configs/application.yaml.tmpl", {
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

resource "kubectl_manifest" "throttler" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: throttler-app
      namespace: argocd
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      destination:
        namespace: argocd
        server: "https://kubernetes.default.svc"
      project: default
      source:
        repoURL: "https://github.com/hasAnybodySeenHarry/cluster"
        targetRevision: HEAD
        path: production/throttler
        helm:
          valueFiles:
          - values.yaml
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
  YAML

  depends_on = [
    helm_release.linkerd_crds,
    helm_release.prometheus_crds,
    helm_release.argocd
  ]
}
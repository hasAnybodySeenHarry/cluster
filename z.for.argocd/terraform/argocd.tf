resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true

  name  = "argocd"
  chart = "argo-cd"

  repository = "https://argoproj.github.io/argo-helm"

  atomic = true
  wait   = true

  set {
    name = "configs.params.server\\.insecure"
    value = true
  }

  set {
    name = "configs.cm.admin\\.enabled"
    value = false
  }
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

# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: argocd-cm
#   namespace: argocd
# data:
#   url: https://<your-argocd-server-domain>
#   dex.config: |
#     connectors:
#     - type: github
#       id: github
#       name: GitHub
#       config:
#         clientID: YOUR_CLIENT_ID
#         clientSecretRef:
#           name: github-oauth-secret
#           key: clientSecret
#         orgs:
#         - name: YOUR_GITHUB_ORG

# kubectl -n argocd create secret generic github-oauth-secret \
#   --from-literal=clientSecret=YOUR_CLIENT_SECRET

# kubectl rollout restart deployment argocd-server -n argocd

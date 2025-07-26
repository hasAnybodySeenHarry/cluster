resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true

  name  = "argocd"
  chart = "argo-cd"

  repository = "https://argoproj.github.io/argo-helm"

  atomic = true

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
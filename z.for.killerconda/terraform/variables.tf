variable "argocd_apps" {
  type = list(
    object({
      app-name        = string
      repository-url  = string
      target-revision = string
      source-path     = string
      server-url      = string
  }))
  description = "The list of environments that house a collection of Argo CD Applications"
}
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

variable "oidc_client_id" {
  sensitive   = true
  description = "The client ID of the GitHub OAuth App"
  type        = string
}

variable "oidc_client_secret" {
  sensitive   = true
  description = "The client secret of the GitHub OAuth App"
  type        = string
}

variable "server_url" {
  description = "The base url of the Argo CD server"
  type        = string
}
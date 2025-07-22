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

variable "prometheus_version" {
  description = "The version of Prometheus"
  default     = "62.3.1"
}

variable "inject_mesh" {
  description = "Whether to inject a data-plane proxy into the prometheus server, false by default"
  type        = bool
  default     = false
}
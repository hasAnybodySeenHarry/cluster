resource "kubernetes_role" "cert_manager_secret_creator" {
  metadata {
    name      = "cert-manager-secret-creator"
    namespace = local.linkerd_ns
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get", "update", "patch"]
  }

  depends_on = [
    kubernetes_namespace.linkerd
  ]
}

resource "kubernetes_role_binding" "cert_manager_secret_creator_binding" {
  metadata {
    name      = "cert-manager-secret-creator-binding"
    namespace = local.linkerd_ns
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "cert-manager-secret-creator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cert-manager"
    namespace = local.cert_manager_ns
  }

  depends_on = [
    kubernetes_namespace.linkerd
  ]
}

resource "helm_release" "cert_manager" {
  namespace        = local.cert_manager_ns
  create_namespace = true

  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.18.2"

  atomic = true

  set {
    name  = "crds.enabled"
    value = "true"
  }

  depends_on = [
    kubernetes_namespace.linkerd
  ]
}

resource "kubectl_manifest" "linkerd_trust_root_issuer" {
  yaml_body = file("${path.module}/certificates/trust_root_issuer.yaml")

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "linkerd_trust_anchor" {
  yaml_body = file("${path.module}/certificates/trust_anchor.yaml")

  depends_on = [
    kubectl_manifest.linkerd_trust_root_issuer
  ]
}

resource "null_resource" "linkerd_previous_anchor" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e

      for i in {1..5}; do
        echo "Attempt $i: Trying to duplicate linkerd-trust-anchor secret"

        if kubectl get secret -n cert-manager linkerd-trust-anchor -o yaml \
          | sed -e s/linkerd-trust-anchor/linkerd-previous-anchor/ \
          | egrep -v '^  *(resourceVersion|uid)' \
          | kubectl apply -f -; then
          echo "Successfully created linkerd-previous-anchor"
          exit 0
        else
          echo "Attempt $i failed. Retrying in 5 seconds."
          sleep 5
        fi
      done

      echo "All retry attempts failed."
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    kubectl_manifest.linkerd_trust_anchor
  ]
}

resource "kubectl_manifest" "linkerd_identity_issuer_issuer" {
  yaml_body = file("${path.module}/certificates/identity_issuer_issuer.yaml")

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "linkerd_identity_issuer" {
  yaml_body = file("${path.module}/certificates/identity_issuer.yaml")

  depends_on = [
    kubectl_manifest.linkerd_identity_issuer_issuer
  ]
}
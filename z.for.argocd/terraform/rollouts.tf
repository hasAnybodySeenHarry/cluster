resource "kubectl_manifest" "rollouts_rbac" {
  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: argo-controller-role
    rules:
    - apiGroups:
      - gateway.networking.k8s.io
      resources:
      - httproutes
      verbs:
      - "*"
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: argo-controller
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: argo-controller-role
    subjects:
    - namespace: argo-rollouts
      kind: ServiceAccount
      name: argo-rollouts
  YAML
}

resource "helm_release" "argo_rollouts" {
  namespace        = "argo-rollouts"
  create_namespace = true

  name  = "argo-rollouts"
  chart = "argo-rollouts"

  repository = "https://argoproj.github.io/argo-helm"
  version    = "v2.40.3"

  set = [
    {
      name  = "controller.trafficRouterPlugins[0].name"
      value = "argoproj-labs/gatewayAPI"
    },
    {
      name  = "controller.trafficRouterPlugins[0].location"
      value = "https://github.com/argoproj-labs/rollouts-plugin-trafficrouter-gatewayapi/releases/download/v0.5.0/gateway-api-plugin-linux-amd64"
    },
    {
      name  = "fullnameOverride"
      value = "argo-rollouts"
    },
    {
      name  = "keepCRDs"
      value = "false"
    }
  ]

  depends_on = [
    kubectl_manifest.rollouts_rbac
  ]
}
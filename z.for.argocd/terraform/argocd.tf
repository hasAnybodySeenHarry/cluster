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
    kubectl_manifest.redis_secret,
    kubectl_manifest.redis,
    kubectl_manifest.redis_service
  ]
}

resource "kubectl_manifest" "redis_secret" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: redis-secrets
    type: Opaque
    data:
      addr: cmVkaXMtZGF0YWJhc2U6NjM3OQ==
      password: cGFzc3dvcmQ=
  YAML
}

resource "kubectl_manifest" "redis" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Pod
    metadata:
      name: redis
      labels:
        app: redis
    spec:
      containers:
      - name: redis-container
        image: redis:alpine
        command: ["sh", "-c", "redis-server --requirepass $REDIS_PASSWORD"]
        ports:
        - containerPort: 6379
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secrets
              key: password
  YAML
}

resource "kubectl_manifest" "redis_service" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: redis-database
      labels:
        app: redis
    spec:
      selector:
        app: redis
      ports:
      - targetPort: 6379
        protocol: TCP
        port: 6379
      type: ClusterIP
  YAML
}

resource "kubectl_manifest" "ingress" {
  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: throttler-ingress
      namespace: default
      annotations:
        nginx.ingress.kubernetes.io/rewrite-target: /
    spec:
      ingressClassName: nginx
      rules:
      - http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: throttler-active
                port:
                  number: 8080
  YAML

  depends_on = [
    helm_release.nginx
  ]
}
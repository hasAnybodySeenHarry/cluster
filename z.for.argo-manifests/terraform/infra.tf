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
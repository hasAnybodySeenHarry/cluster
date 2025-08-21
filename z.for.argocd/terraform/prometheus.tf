resource "helm_release" "prometheus_crds" {
  namespace        = "monitoring"
  create_namespace = true

  name    = "prometheus-operator-crds"
  chart   = "prometheus-operator-crds"
  version = "v22.0.1"

  repository = "https://prometheus-community.github.io/helm-charts"

  atomic = true
}

resource "helm_release" "prometheus" {
  count = 0

  name             = "prometheus"
  namespace        = helm_release.prometheus_crds.namespace
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "v76.3.0"
  create_namespace = true

  set = concat(
    [
      {
        name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
        value = "false"
      }
    ],
    // conditionally add this if var.inject_mesh is true
    var.inject_mesh ? [
      {
        name  = "prometheus.prometheusSpec.podMetadata.annotations.linkerd\\.io/inject"
        value = "enabled"
      }
    ] : []
  )

  values = [
    <<-EOT
      grafana:
        enabled: true
      alertmanager:
        enabled: false
      kubeStateMetrics:
        enabled: false
      nodeExporter:
        enabled: false
    EOT
  ]

  depends_on = [
    helm_release.linkerd,
    helm_release.linkerd_crds
  ]
}

resource "kubectl_manifest" "control_plane_monitor" {
  yaml_body = <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PodMonitor
    metadata:
      labels:
        linkerd.io/control-plane-ns: linkerd
      name: linkerd-proxy
      namespace: linkerd
    spec:
      namespaceSelector:
        any: true
      podMetricsEndpoints:
      - interval: 10s
        relabelings:
        - action: keep
          regex: ^linkerd-proxy;linkerd-admin;linkerd$
          sourceLabels:
          - __meta_kubernetes_pod_container_name
          - __meta_kubernetes_pod_container_port_name
          - __meta_kubernetes_pod_label_linkerd_io_control_plane_ns
        - action: replace
          sourceLabels:
          - __meta_kubernetes_namespace
          targetLabel: namespace
        - action: replace
          sourceLabels:
          - __meta_kubernetes_pod_name
          targetLabel: pod
        - action: replace
          sourceLabels:
          - __meta_kubernetes_pod_label_linkerd_io_proxy_job
          targetLabel: k8s_job
        - action: labeldrop
          regex: __meta_kubernetes_pod_label_linkerd_io_proxy_job
        - action: labelmap
          regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
        - action: labeldrop
          regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
        - action: labelmap
          regex: __meta_kubernetes_pod_label_linkerd_io_(.+)
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
          replacement: __tmp_pod_label_$1
        - action: labelmap
          regex: __tmp_pod_label_linkerd_io_(.+)
          replacement: __tmp_pod_label_$1
        - action: labeldrop
          regex: __tmp_pod_label_linkerd_io_(.+)
        - action: labelmap
          regex: __tmp_pod_label_(.+)
        scrapeTimeout: 10s
      selector:
        matchLabels: {}
  YAML

  depends_on = [
    helm_release.prometheus_crds
  ]
}

resource "kubectl_manifest" "data_plane_monitor" {
  yaml_body = <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PodMonitor
    metadata:
      labels:
        linkerd.io/control-plane-ns: linkerd
      name: linkerd-controller
      namespace: linkerd
    spec:
      namespaceSelector:
        matchNames:
        - linkerd
        - linkerd-viz
      podMetricsEndpoints:
      - interval: 10s
        relabelings:
        - action: keep
          regex: admin-http
          sourceLabels:
          - __meta_kubernetes_pod_container_port_name
        - action: replace
          sourceLabels:
          - __meta_kubernetes_pod_container_name
          targetLabel: component
        scrapeTimeout: 10s
      selector:
        matchLabels: {}
  YAML

  depends_on = [
    helm_release.prometheus_crds,
    helm_release.linkerd_crds
  ]
}
variable "inject_mesh" {
  type        = bool
  default     = false
  description = "Whether to inject data plane proxies into prometheus components"
}

# controlplane:~$ cat nodeexporterrules.yaml 
# apiVersion: monitoring.coreos.com/v1
# kind: PrometheusRule
# metadata:
#   name: my-nodeexporter-rules
#   namespace: monitoring
#   labels:
#     release: prometheus
# spec:
#   groups:
#   - name: node-exporter
#     rules:
#     - alert: NodeExporterDown
#       expr: up{job="node-exporter"} == 0
#       for: 1m
#       labels:
#         severity: critical
#       annotations:
#         summary: "Node Exporter is down"
#         description: "Prometheus target on {{ $labels.instance }} unreachable >1m."

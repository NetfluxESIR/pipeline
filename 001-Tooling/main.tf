resource "helm_release" "cert_manager" {
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  name             = "cert-manager"
  namespace        = "tooling"
  version          = "v1.11.0"
  create_namespace = true
  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  name             = "monitoring"
  namespace        = "tooling"
  create_namespace = true
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}
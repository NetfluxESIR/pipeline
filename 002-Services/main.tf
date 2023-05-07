resource "helm_release" "argo_workflow" {
  chart            = "argo-workflows"
  name             = "argo-workflows"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = "argo"
  create_namespace = true
  set {
    name  = "workflow.workflowNamespaces[0]"
    value = "video-pipeline"
  }
  set {
    name  = "controller.metricsConfig.enabled"
    value = "true"
  }
  set {
    name  = "controller.serviceMonitor.enabled"
    value = "true"
  }
  depends_on = [kubernetes_namespace.video_pipeline_ns]
}

resource "kubernetes_namespace" "video_pipeline_ns" {
  metadata {
    name = "video-pipeline"
  }
}


resource "helm_release" "argo_events" {
  chart            = "argo-events"
  name             = "argo-events"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = "argo"
  create_namespace = true
  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }
  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }
}

locals {
  minio_access_key = uuid()
  minio_secret_key = uuid()
}

resource "helm_release" "minio_operator" {
  chart            = "minio-operator"
  name             = "minio-operator"
  repository       = "https://operator.min.io/"
  namespace        = "minio-operator"
  create_namespace = true
}

resource "helm_release" "minio_video_tenant" {
  name             = "tenant"
  chart            = "./charts/tenant"
  namespace        = "video-pipeline-minio"
  create_namespace = true
  depends_on       = [helm_release.minio_operator]
  values = [
    templatefile("${path.module}/template/minio_tenant_values.yaml.tftpl", {
      minio_access_key = local.minio_access_key
      minio_secret_key = local.minio_secret_key
      namespace        = "video-pipeline-minio"
  })]
}

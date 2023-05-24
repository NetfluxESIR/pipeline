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

// Create bucket as sometimes the minio operator doesn't create it
resource "kubernetes_config_map" "create_bucket" {
  metadata {
    name      = "create-bucket"
    namespace = "video-pipeline-minio"
  }
  data = {
    "create-bucket.sh" = <<EOF
#!/bin/sh
until mc alias set video-pipeline http://minio.${helm_release.minio_video_tenant.namespace}.svc.cluster.local "${local.minio_access_key}" "${local.minio_secret_key}"
do
  echo "Waiting for Minio to be available"
  sleep 1
done
mc mb --ignore-existing video-pipeline/video-pipeline
mc mb --ignore-existing video-pipeline/video-pipeline-processed
EOF
  }
  depends_on = [helm_release.minio_video_tenant]
}

resource "kubernetes_job_v1" "video_bucket_creation" {
  timeouts {
    create = "15m"
  }
  metadata {
    name      = "video-bucket-creation"
    namespace = "video-pipeline-minio"
  }
  spec {
    ttl_seconds_after_finished = 10
    template {
      spec {
        container {
          name    = "mc"
          image   = "minio/mc"
          command = ["/bin/sh", "./scripts/create-bucket.sh"]
          volume_mount {
            name       = "scripts"
            mount_path = "/scripts"
          }
          env {
            name  = "MINIO_HOST"
            value = "minio.${helm_release.minio_video_tenant.namespace}.svc.cluster.local"
          }
          env {
            name  = "MINIO_ACCESS_KEY"
            value = local.minio_access_key
          }
          env {
            name  = "MINIO_SECRET_KEY"
            value = local.minio_secret_key
          }
        }
        volume {
          name = "scripts"
          config_map {
            name         = "create-bucket"
            default_mode = "0777"
          }
        }
      }
      metadata {}
    }
  }
  depends_on = [kubernetes_config_map.create_bucket]
}
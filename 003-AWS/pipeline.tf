resource "kubernetes_secret" "private-regcred-video-pipeline" {
  metadata {
    name      = "private-regcred"
    namespace = "video-pipeline"
  }
  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.registry_server) = {
          "username" = var.github_username
          "password" = var.github_token
          "auth"     = base64encode("${var.github_username}:${var.github_token}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "private-regcred-argo" {
  metadata {
    name      = "private-regcred"
    namespace = "argo"
  }
  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.registry_server) = {
          "username" = var.github_username
          "password" = var.github_token
          "auth"     = base64encode("${var.github_username}:${var.github_token}")
        }
      }
    })
  }
}

resource "helm_release" "video_pipeline" {
  chart     = "./charts/video-pipeline"
  name      = "video-pipeline"
  namespace = "argo"
  values = [
    templatefile("${path.module}/templates/pipeline-cfg.yaml.tftpl", {
      minio_url                = data.terraform_remote_state.service_state.outputs.minio_url
      minio_access_key         = data.terraform_remote_state.service_state.outputs.minio_access_key
      minio_secret_key         = data.terraform_remote_state.service_state.outputs.minio_secret_key
      backend_url              = "http://${aws_instance.backend_host.public_ip}"
      backend_account_email    = var.admin_account_email
      backend_account_password = var.admin_account_password
      backend_account_role     = "ADMIN"
      image_pull_secret        = kubernetes_secret.private-regcred-video-pipeline.metadata.0.name
    })
  ]
  depends_on = [
    kubernetes_secret.private-regcred-video-pipeline,
    kubernetes_secret.private-regcred-argo,
    aws_instance.backend_host
  ]
}

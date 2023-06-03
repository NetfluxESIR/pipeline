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
    })
  ]
  depends_on = [
    aws_instance.backend_host
  ]
}

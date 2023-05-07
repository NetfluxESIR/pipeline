data "terraform_remote_state" "service_state" {
  backend = "local"
  config = {
    path = "${path.module}/../002-Services/terraform.tfstate"
  }
}

resource "helm_release" "video_pipeline" {
  chart     = "./charts/video-pipeline"
  name      = "video-pipeline"
  namespace = "video-pipeline"
  values = [
    templatefile("${path.module}/template/pipeline-cfg.yaml.tftpl", {
      minio_url        = data.terraform_remote_state.service_state.outputs.minio_url
      minio_access_key = data.terraform_remote_state.service_state.outputs.minio_access_key
      minio_secret_key = data.terraform_remote_state.service_state.outputs.minio_secret_key
    })
  ]
}

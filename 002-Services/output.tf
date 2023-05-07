output "minio_url" {
  value = "minio.${helm_release.minio_video_tenant.namespace}.svc.cluster.local"
}

output "minio_access_key" {
  value = local.minio_access_key
}

output "minio_secret_key" {
  value = local.minio_secret_key
}

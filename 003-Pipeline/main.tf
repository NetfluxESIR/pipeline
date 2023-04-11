resource "helm_release" "argo_workflow" {
  chart = "argo-workflows"
  name  = "argo-workflows"
  repository = "https://argoproj.github.io/argo-helm"
}

resource "helm_release" "argo_events" {
  chart = "argo-events"
  name  = "argo-events"
  repository = "https://argoproj.github.io/argo-helm"
}

resource "helm_release" "minio" {
  chart = "minio"
  name  = "minio"
  repository = "https://charts.bitnami.com/bitnami"
}
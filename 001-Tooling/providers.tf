provider "helm" {
  kubernetes {
    config_path = "${path.module}/../000-Cluster/kind-config"
  }
}
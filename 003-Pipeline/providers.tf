provider "helm" {
  kubernetes {
    config_path = "${path.module}/../000-Cluster/kubeconfig"
  }
}

provider "kubernetes" {
  config_path = "${path.module}/../000-Cluster/kubeconfig"
}
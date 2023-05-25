module "kind" {
  source             = "git::https://github.com/camptocamp/devops-stack-module-kind.git?ref=v2.1.2"
  kubernetes_version = "v1.26.0"
  cluster_name       = var.cluster_name
}

resource "local_file" "kubeconfig" {
  content  = module.kind.raw_kubeconfig
  filename = "${path.module}/kind-config"
}
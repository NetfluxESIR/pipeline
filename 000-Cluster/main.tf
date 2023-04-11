module "kind" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kind.git?ref=v2.1.2"

  cluster_name = var.cluster_name

  kubernetes_version = "1.25.3"
}

output "kubeconfig" {
  sensitive = true
  value     = module.kind.parsed_kubeconfig
}

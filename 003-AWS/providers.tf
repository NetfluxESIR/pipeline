terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}


provider "kubernetes" {
  config_path = "${path.module}/../000-Cluster/kind-config"
}
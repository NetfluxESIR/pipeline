# 000-Cluster

This folder contains to terraform code to create a kubernetes cluster using kind.

This cluster is used to deploy the other resources of the project.

If you want to use an existing cluster, you can skip this step.

## Usage

```bash
terraform init
terraform apply
```

## Input

| Name          | Description             |  Type  | Default  | Required |
|---------------|-------------------------|:------:|:--------:|:--------:|
| cluster\_name | The name of the cluster | string | `"kind"` |    no    |

# Netflux ESIR - Pipeline

This repository contains the Terraform code to deploy the Netflux ESIR project.

If you want to deploy the project, you can follow the instructions below.

## Requirements

Please make sure you have the following tools installed on your machine :

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Python 3](https://www.python.org/downloads/)
- [make](https://www.gnu.org/software/make/)
- [helm](https://helm.sh/docs/intro/install/)
- [An AWS account with sufficient permissions](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/) in order to create a bucket, EC2 instances and an user with the required permissions to interact with the S3 bucket
- [Docker](https://docs.docker.com/get-docker/) with a rootless configuration (see [this page](https://docs.docker.com/engine/security/rootless/) for more information)
- [Git](https://git-scm.com/downloads)
- [nodejs](https://nodejs.org/en/download/) and npm (installed with nodejs normally)

## Values available

The following variables are available to customize the deployment :

| Name                   | Description                                  | Type     | Default             | Required |
|------------------------|----------------------------------------------|----------|---------------------|:--------:|
| cluster_name           | Kubernetes cluster name                      | `string` | `"kind"`            |    no    |
| admin_account_email    | Admin account email - login for fronted      | `string` | `"admin@admin.com"` |    no    |
| admin_account_password | Admin account password  - login for frontend | `string` | `"admin`            |    no    |
| registry_server        | Registry server used to pull images          | `string` | `"ghcr.io"`         |    no    |

## Usage

See the [Makefile](./Makefile) for more information about the commands.

#### Tfvars file

A `.tfvars` file is required to deploy the cluster. You can find an example below :

```hcl
cluster_name = "kind"
admin_account_email = "admin@admin.com"
admin_account_password = "admin"
registry_server = "ghcr.io"
```

### Deploy

> Note that you have to set "AWS_ACCESS_KEY_ID" and "AWS_SECRET_ACCESS_KEY" environment variables to deploy the cluster.
> 
> See [this page](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) for more information.

To deploy the cluster, you need to run the following command :

```bash
git clone https://github.com/NetfluxESIR/pipeline.git
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
make deploy VAR_FILE=/path/to/your/vars.tfvars
```

Then you can access the frontend using the frontend url outputted by terraform.

## Destroy

```bash
make destroy VAR_FILE=/path/to/your/vars.tfvars
```
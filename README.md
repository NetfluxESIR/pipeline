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
- [Docker](https://docs.docker.com/get-docker/) manageable by a non-root user (see [this page](https://docs.docker.com/engine/install/linux-postinstall/) for more information) and running.
- [Git](https://git-scm.com/downloads)
- [nodejs](https://nodejs.org/en/download/) and npm (installed with nodejs normally) - Node Version >= 18.16.0

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

To deploy the cluster, you need to run the following command with your information :

```bash
git clone https://github.com/NetfluxESIR/pipeline.git
cd pipeline
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
make deploy VAR_FILE=/absolute/path/to/your/vars.tfvars
```

Then you can access the frontend using the frontend url outputted by terraform.

## Destroy

```bash
make destroy VAR_FILE=/absolute/path/to/your/vars.tfvars
```

## Troubleshooting

Many problems can occur during the deployment of the cluster. Here are some solutions to the most common problems.

### Timeout when deploying the cluster

It happens sometimes that the cluster deployment fails because of a timeout. If it happens, you can try to deploy the cluster again using the following command :

```bash
make deploy VAR_FILE=/absolute/path/to/your/vars.tfvars
```

It will continue the deployment where it stopped.

### Too many open files

It happens sometimes that containers can't start because of a "too many open files" error. If it happens, you can try to deploy the cluster again using the following command :

```bash
ulimit -n 65536
sudo sysctl fs.inotify.max_user_instances=1280
sudo sysctl fs.inotify.max_user_watches=655360
make destroy VAR_FILE=/absolute/path/to/your/vars.tfvars
make deploy VAR_FILE=/absolute/path/to/your/vars.tfvars
```

See [this page](https://github.com/kubeflow/manifests/issues/2087) for more information.

### Site is not pushed to S3

It happens sometimes that the site is not pushed to S3. If it happens, you can try to deploy the cluster again using the following command :

```bash
cd 003-Netflux
terraform apply -var-file=/absolute/path/to/your/vars.tfvars -auto-approve
```

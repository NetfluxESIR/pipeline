VAR_FILE ?= "terraform.tfvars"

000:
	cd 000-Cluster
	terraform init
	terraform apply -auto-approve -var-file=$(VAR_FILE)

001: 000
	cd 001-Tooling
	terraform init
	terraform apply -auto-approve -var-file=$(VAR_FILE)

002: 001
	cd 002-Services
	terraform init
	terraform apply -auto-approve -var-file=$(VAR_FILE)

003: 002
	cd 003-Pipeline
	terraform init
	terraform apply -auto-approve -var-file=$(VAR_FILE)

deploy: 004
	echo "Stack deployed"
VAR_FILE ?= "terraform.tfvars"
CURRENT_DIR = $(shell pwd)

000:
	cd $(CURRENT_DIR)/000-Cluster && terraform init && terraform apply -auto-approve -var-file=$(VAR_FILE)

001: 000
	cd $(CURRENT_DIR)/001-Tooling && terraform init && terraform apply -auto-approve -var-file=$(VAR_FILE)

002: 001
	cd $(CURRENT_DIR)/002-Services && terraform init && terraform apply -auto-approve -var-file=$(VAR_FILE)

003: 002
	cd $(CURRENT_DIR)/003-AWS && terraform init && terraform apply -auto-approve -var-file=$(VAR_FILE)

deploy: 003
	echo "Stack deployed"

destroy:
	cd $(CURRENT_DIR)/003-AWS && terraform destroy -auto-approve -var-file=$(VAR_FILE)
	cd $(CURRENT_DIR)/002-Services && terraform destroy -auto-approve -var-file=$(VAR_FILE)
	cd $(CURRENT_DIR)/001-Tooling && terraform destroy -auto-approve -var-file=$(VAR_FILE)
	cd $(CURRENT_DIR)/000-Cluster && terraform destroy -auto-approve -var-file=$(VAR_FILE)
	echo "Stack destroyed"
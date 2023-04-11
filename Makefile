000:
	cd 000-Cluster
	terraform init
	terraform apply -auto-approve

001: 000
	cd 001-Tooling
	terraform init
	terraform apply -auto-approve

002: 001
	cd 002-Services
	terraform init
	terraform apply -auto-approve

003: 002
	cd 003-Pipeline
	terraform init
	terraform apply -auto-approve

004: 003
	cd 004-Monitoring
	terraform init
	terraform apply -auto-approve

deploy: 004
	echo "Stack deployed"
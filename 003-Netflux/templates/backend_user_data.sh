#!/bin/bash
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce
usermod -aG docker ubuntu
docker run -p 0.0.0.0:80:8080 -d --env=AWS_ACCESS_KEY_ID=${aws_access_key} --env=AWS_SECRET_ACCESS_KEY=${aws_secret_key} ghcr.io/netfluxesir/backend:latest serve -H=0.0.0.0 --dsn=postgres://${db_user}:${db_pass}@${db_host}/${db_name}?sslmode=require -l=trace -a=${admin_account_email} -P=${admin_account_password} -b=${bucket_name} -r=${region}
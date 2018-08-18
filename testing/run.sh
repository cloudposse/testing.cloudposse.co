#!/usr/bin/env bash

echo "Hello!"

mkdir -p ${AWS_DATA_PATH}

echo '[default]' > ${AWS_CONFIG_FILE}

aws s3 ls

cd /conf/kops

init-terraform

terraform plan

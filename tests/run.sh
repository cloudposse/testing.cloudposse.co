#!/usr/bin/env bash

aws s3 ls

cd /conf/kops

init-terraform

terraform plan

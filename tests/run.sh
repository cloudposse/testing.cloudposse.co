#!/usr/bin/env bash

# Exit on all errors
set -e

aws s3 ls

cd /conf/kops

init-terraform

terraform plan

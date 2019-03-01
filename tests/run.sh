#!/usr/bin/env bash


# Exit on all errors
set -e

cd /conf/tests && eval "$(direnv export bash)"
cd /conf/acm   && eval "$(direnv export bash)"

terraform init

terraform plan

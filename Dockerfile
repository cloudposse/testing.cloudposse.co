ARG VERSION=0.147.7
ARG OS=alpine
FROM cloudposse/geodesic:$VERSION-$OS

ENV DOCKER_IMAGE="cloudposse/testing.cloudposse.co"
ENV DOCKER_TAG="latest"

# General
ENV NAMESPACE="cpco"
ENV STAGE="testing"
ENV ZONE_ID="Z3SO0TKDDQ0RGG"

# Geodesic banner
ENV BANNER="testing"

# Message of the Day
ENV MOTD_URL="https://geodesic.sh/motd"

# AWS
ENV AWS_REGION="us-west-2"
ENV REGION="${AWS_REGION}"
ENV AWS_ACCOUNT_ID="126450723953"
ENV ACCOUNT_ID="${AWS_ACCOUNT_ID}"
ENV AWS_ROOT_ACCOUNT_ID="323330167063"

# chamber KMS config
ENV CHAMBER_KMS_KEY_ALIAS="alias/${NAMESPACE}-${STAGE}-chamber"

# Terraform State Bucket
ENV TF_BUCKET_PREFIX_FORMAT="basename-pwd"
ENV TF_BUCKET_REGION="${AWS_REGION}"
ENV TF_BUCKET="${NAMESPACE}-${STAGE}-terraform-state"
ENV TF_DYNAMODB_TABLE="${NAMESPACE}-${STAGE}-terraform-state-lock"

# Our older Geodesic configurations relied on `direnv`, which we no longer recommend,
# preferring YAML configuration files instead.
ENV DIRENV_ENABLED=true
# Our older Geodesic configuration uses multiple Makefiles, like Makefile.tasks
# and depends on this setting, however this setting is set by default by `direnv`
# due to rootfs/conf/.envrc, but `direnv` is now disabled by default, too.
# If you are using (and therefore enable) `direnv`, consider the advantage
# of using `direnv` to set MAKE_INCLUDES, which is that it will only set
# it for trusted directories under `/conf` and therefore it will not affect
# `make` outside of this directory tree.
ENV MAKE_INCLUDES="Makefile Makefile.*"

# Default AWS Profile name
ENV AWS_DEFAULT_PROFILE="${NAMESPACE}-${STAGE}-admin"
ENV AWS_MFA_PROFILE="${NAMESPACE}-root-admin"

# aws-vault setup
ENV AWS_VAULT_ASSUME_ROLE_TTL=1h
ENV AWS_VAULT_SERVER_ENABLED=false
ENV AWS_VAULT_BACKEND=file
ENV AWS_VAULT_ENABLED=true
RUN apk add -u aws-vault@cloudposse~=4

# Install go for running terratest
RUN apk add go@community --allow-untrusted

## Install terraform-config-inspect (required for bats tests)
ENV GO111MODULE="on"
RUN go install github.com/hashicorp/terraform-config-inspect@latest && \
    mv $(go env GOPATH)/bin/terraform-config-inspect /usr/local/bin/

# Install every "major" version of Terraform so we can use whichever one we want
RUN apk add -uU --force-broken-world \
             terraform@cloudposse      \
             terraform-0.11@cloudposse \
             terraform-0.12@cloudposse \
             terraform-0.13@cloudposse \
             terraform-0.14@cloudposse \
             terraform-0.15@cloudposse \
             terraform-1@cloudposse

# Use aws-vault for credentials
ENV AWS_VAULT_ENABLED=true
# Pin aws-vault to a version <5.0
# There are bugs with aws credential caching that make version 5 more annoying to use; see:
# https://github.com/99designs/aws-vault/issues/552
# https://github.com/cloudposse/geodesic/pull/579
# There are other bugs with version 6.0
# https://github.com/99designs/aws-vault/issues/689
# and until IMDSv2 is supported, aws-vault server does not work with kops 1.18
# https://github.com/99designs/aws-vault/issues/690
RUN apk add -uU aws-vault@cloudposse~=4 --force-broken-world

# Filesystem entry for tfstate
RUN s3 fstab '${TF_BUCKET}' '/' '/secrets/tf'

# Use `direnv` for configuration
ENV DIRENV_ENABLED=true
# Support make-based builds
ENV MAKE_INCLUDES="Makefile Makefile.*"
# Explicitly set  KUBECONFIG to enable kube_ps1 prompt
ENV KUBECONFIG=/conf/.kube/config

# kops config
ENV KOPS_CLUSTER_NAME="us-west-2.testing.cloudposse.co"
ENV KOPS_DNS_ZONE=${KOPS_CLUSTER_NAME}
ENV KOPS_STATE_STORE="s3://${NAMESPACE}-${STAGE}-kops-state"
ENV KOPS_STATE_STORE_REGION="us-west-2"
ENV KOPS_AVAILABILITY_ZONES="us-west-2a,us-west-2b,us-west-2c"
ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV KOPS_AWS_IAM_AUTHENTICATOR_ENABLED="true"
ENV BASTION_MACHINE_TYPE="t2.medium"
ENV MASTER_MACHINE_TYPE="t2.medium"
ENV NODE_MACHINE_TYPE="t2.medium"
ENV NODE_MAX_SIZE="4"
ENV NODE_MIN_SIZE="4"

COPY rootfs/ /

# Place configuration in 'conf/' directory
COPY conf/ /conf/
RUN touch $KUBECONFIG && chmod 600 $KUBECONFIG

# Install atlantis
RUN curl -fsSL -o /usr/bin/atlantis https://github.com/cloudposse/atlantis/releases/download/0.9.0.3/atlantis_linux_amd64 && \
    chmod 755 /usr/bin/atlantis

WORKDIR /conf/

FROM cloudposse/helmfiles:0.8.6 as helmfiles

FROM cloudposse/geodesic:0.114.0

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

# Default AWS Profile name
ENV AWS_DEFAULT_PROFILE="${NAMESPACE}-${STAGE}-admin"
ENV AWS_MFA_PROFILE="${NAMESPACE}-root-admin"

# Install terraform 0.11 for backwards compatibility
RUN apk add terraform_0.11@cloudposse terraform_0.12@cloudposse terraform@cloudposse==0.11.14-r0

# Pin helm to 2.14 for stability
RUN apk add helm@cloudposse==2.14.0-r0

# Copy helmfiles
COPY --from=helmfiles /helmfile.d/ /conf/helmfile.d/
COPY --from=helmfiles /scripts/ /conf/scripts/

# Place configuration in 'conf/' directory
COPY conf/ /conf/

# Filesystem entry for tfstate
RUN s3 fstab '${TF_BUCKET}' '/' '/secrets/tf'

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

# Install atlantis
RUN curl -fsSL -o /usr/bin/atlantis https://github.com/cloudposse/atlantis/releases/download/0.8.0/atlantis_linux_amd64 && \
    chmod 755 /usr/bin/atlantis

WORKDIR /conf/

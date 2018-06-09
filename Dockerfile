FROM cloudposse/terraform-root-modules:0.3.3 as terraform-root-modules

FROM cloudposse/geodesic:0.9.18

ENV DOCKER_IMAGE="cloudposse/testing.cloudposse.co"
ENV DOCKER_TAG="latest"

ENV BANNER="testing.cloudposse.co"

# Default AWS Profile name
ENV AWS_DEFAULT_PROFILE="cpco-testing-admin"

# AWS Region
ENV AWS_REGION="us-west-2"

# Terraform State Bucket
ENV TF_BUCKET="cpco-testing-terraform-state"
ENV TF_BUCKET_REGION="us-west-2"
ENV TF_DYNAMODB_TABLE="cpco-testing-terraform-state-lock"

# Terraform vars
# https://www.terraform.io/docs/configuration/variables.html
ENV TF_VAR_account_id="126450723953"
ENV TF_VAR_region="us-west-2"
ENV TF_VAR_namespace="cpco"
ENV TF_VAR_stage="testing"
ENV TF_VAR_domain_name="testing.cloudposse.co"

# chamber KMS config
ENV CHAMBER_KMS_KEY_ALIAS="alias/cpco-testing-chamber"

# Copy root modules
COPY --from=terraform-root-modules /aws/tfstate-backend/ /conf/tfstate-backend/
COPY --from=terraform-root-modules /aws/account-dns/ /conf/account-dns/
COPY --from=terraform-root-modules /aws/acm/ /conf/acm/
COPY --from=terraform-root-modules /aws/backing-services/ /conf/backing-services/
COPY --from=terraform-root-modules /aws/chamber/ /conf/chamber/
COPY --from=terraform-root-modules /aws/cloudtrail/ /conf/cloudtrail/
COPY --from=terraform-root-modules /aws/kops/ /conf/kops/
COPY --from=terraform-root-modules /aws/kops-aws-platform/ /conf/kops-aws-platform/

# Filesystem entry for tfstate
RUN s3 fstab '${TF_BUCKET}' '/' '/secrets/tf'

# kops config
ENV KOPS_CLUSTER_NAME="us-west-2.testing.cloudposse.co"
ENV KOPS_DNS_ZONE=${KOPS_CLUSTER_NAME}
ENV KOPS_STATE_STORE="s3://cpco-testing-kops-state"
ENV KOPS_STATE_STORE_REGION="us-west-2"
ENV KOPS_AVAILABILITY_ZONES="us-west-2a,us-west-2b,us-west-2c"
ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV BASTION_MACHINE_TYPE="t2.medium"
ENV MASTER_MACHINE_TYPE="t2.medium"
ENV NODE_MACHINE_TYPE="t2.medium"
ENV NODE_MAX_SIZE="2"
ENV NODE_MIN_SIZE="2"

# Generate kops manifest
RUN build-kops-manifest

WORKDIR /conf/

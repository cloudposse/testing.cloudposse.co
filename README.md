# testing.cloudposse.co

Terraform/Kubernetes Infrastructure for CloudPosse Testing Organization in AWS.

__NOTE:__ Before creating the testing infrastructure, you need to provision the Parent ("Root") Organization in AWS (because it creates resources needed for all other accounts).

Follow the steps in [README](https://github.com/cloudposse/root.cloudposse.co/blob/master/README.md) first. You need to do it only once.


## Introduction

We use [geodesic](https://github.com/cloudposse/geodesic) to define and build world-class cloud infrastructures backed by AWS and powered by Kubernetes.

`geodesic` exposes many tools that can be used to define and provision AWS and Kubernetes resources.

Here is the list of tools we use to provision `cloudposse.co` infrastructure:

* [aws-vault](https://github.com/99designs/aws-vault)
* [chamber](https://github.com/segmentio/chamber)
* [terraform](https://www.terraform.io/)
* [kops](https://github.com/kubernetes/kops)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
* [helm](https://helm.sh/)
* [helmfile](https://github.com/roboll/helmfile)


## Quick Start

### Setup AWS Role

__NOTE:__ You need to do it only once.

Configure AWS profile in `~/.aws/config`. Make sure to change username (username@cloudposse.com) to your own.

```bash
[profile cpco-testing-admin]
region=us-west-2
role_arn=arn:aws:iam::126450723953:role/OrganizationAccountAccessRole
mfa_serial=arn:aws:iam::323330167063:mfa/admin@cloudposse.co
source_profile=cpco
```


### Install and setup aws-vault

__NOTE:__ You need to do it only once.

We use [aws-vault](https://github.com/99designs/aws-vault)
to store IAM credentials in your operating system's secure keystore and then generates temporary credentials from those to expose to your shell and applications.

Install [aws-vault](https://github.com/99designs/aws-vault/releases) on your local computer first.

On MacOS, you may use `homebrew cask`

```bash
brew cask install aws-vault
```

Then setup your secret credentials in `aws-vault`
```bash
aws-vault add --backend file cloudposse
```

For more info, see [aws-vault](https://docs.cloudposse.com/docs/aws-vault)


### Build Docker Image
```
# Initialize the project's build-harness
make init

# Build docker image
make docker/build
```


### Install the wrapper shell
```bash
make install
```


### Run the shell
```bash
testing.cloudposse.co
```


### Login to AWS with your MFA device
```bash
assume-role
```


### Populate `chamber` secrets

__NOTE:__ You need to do it only once. Repeat this step if you want to add new secrets or update existing secrets.

To add a secret for a given service, use the following command:

```bash
chamber write <service> <key1> <value1>
```

Populate `chamber` secrets for `kops` project. The secrets are listed in [chamber-kops.sh](conf/chamber/chamber-kops.sh).
Make sure to change `XXXXXXXXXXXX` to the required values to reflect your environment (don't commit sensitive data, e.g. passwords and API keys). Add new secrets as needed.

```bash
cd /conf/chamber
chmod +x ./chamber-kops.sh
./chamber-kops.sh
chamber list -e kops   # list the secrets stored for `kops` project
```

Populate `chamber` secrets for `backing-services` project. The secrets are listed in [chamber-backing-services.sh](conf/chamber/chamber-backing-services.sh).
Make sure to change `XXXXXXXXXXXX` to the required values to reflect your environment (don't commit sensitive data, e.g. passwords and API keys). Add new secrets as needed.

```bash
cd /conf/chamber
chmod +x ./chamber-backing-services.sh
./chamber-backing-services.sh
chamber list -e backing-services    # list the secrets stored for `backing-services` project
```


<br/>
<br/>

__NOTE:__ Before provisioning AWS resources with Terraform, you need to create `tfstate-backend` first (S3 bucket to store Terraform state and DynamoDB table for state locking).

Follow the steps in this [README](conf/tfstate-backend/README.md). You need to do it only once.

After `tfstate-backend` has been provisioned, follow the rest of the instructions in the order shown below.

<br/>

### Provision `dns` with Terraform

Change directory to `dns` folder
```bash
cd /conf/dns
```

Run Terraform
```bash
init-terraform
terraform plan
terraform apply
```

For more info, see [geodesic-with-terraform](https://docs.cloudposse.com/v0.9.0/docs/geodesic-with-terraform)


### Provision `cloudtrail` with Terraform

```bash
cd /conf/cloudtrail
init-terraform
terraform plan
terraform apply
```


### Provision `acm` with Terraform

```bash
cd /conf/acm
init-terraform
terraform plan
terraform apply
```


### Provision `chamber` with Terraform

```bash
cd /conf/chamber
init-terraform
terraform plan
terraform apply
```


### Provision the Kops cluster

We create a `kops` cluster from a manifest.

The manifest template is located in [`/templates/kops/default.yaml`](https://github.com/cloudposse/geodesic/blob/master/rootfs/templates/kops/default.yaml)
and is compiled by running `build-kops-manifest` in the [`Dockerfile`](Dockerfile).

Provisioning a `kops` cluster takes three steps:

1. Provision the `kops` backend (config S3 bucket, cluster DNS zone, and SSH keypair to access the k8s masters and nodes) in Terraform
2. Update the [`Dockerfile`](Dockerfile) and rebuild/restart the `geodesic` shell to generate a `kops` manifest file
3. Execute the `kops` manifest file to create the `kops` cluster


Change directory to `kops` folder
```bash
cd /conf/kops
```

Run Terraform to provision the `kops` backend (S3 bucket, DNS zone, and SSH keypair)
```bash
init-terraform
terraform plan
terraform apply
```

From the Terraform outputs, copy the `zone_name` and `bucket_name` into the ENV vars `KOPS_CLUSTER_NAME` and `KOPS_STATE_STORE` in the [`Dockerfile`](Dockerfile).

The `Dockerfile` `kops` config should look like this:

```docker
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
```

Type `exit` (or hit ^D) to leave the shell.

Note, if you've assumed a role, you'll first need to leave that also by typing `exit` (or hit ^D).

Rebuild the Docker image
```
make docker/build
```

Run the `geodesic` shell again and assume role to login to AWS
```bash
testing.cloudposse.co
assume-role
```

Change directory to `kops` folder, init Terraform, and list files
```bash
cd /conf/kops
init-terraform
ls
```

You will see the `kops` manifest file `manifest.yaml` generated.

Run `kops create -f manifest.yaml` to create the cluster (this will just create the cluster state and store it in the S3 bucket, but not the AWS resources for the cluster).

Run `kops create secret sshpublickey admin -i /secrets/tf/ssh/cpco-testing-kops-us-west-2.pub --name $KOPS_CLUSTER_NAME` to add the SSH public key to the cluster.

Run `kops update cluster --yes` to provision the AWS resources for the cluster.

All done. The `kops` cluster is now up and running.


__NOTE:__ If you want to change `kops` cluster settings (e.g. number of nodes, instance types, etc.):

1. Modify the `kops` settings in the [`Dockerfile`](Dockerfile)
2. Rebuild Docker image (`make docker/build`)
3. Run `geodesic` shell (`testing.cloudposse.co`), assume role (`assume-role`) and change directory to `kops` folder
4. Run `kops replace -f manifest.yaml` to replace the cluster resources (update state)
5. Run `kops update cluster --yes` to modify the AWS resources for the cluster


__NOTE:__ To force a rolling update (replace the EC2 instances), run `kops rolling-update cluster --yes --force`


__NOTE:__ To use `kops` and `kubectl` commands (_e.g._ `kubectl get nodes`, `kubectl get pods`), you need to export the `kubecfg` configuration settings from the cluster.

https://github.com/kubernetes/kops/blob/master/docs/kubectl.md

Run `kops export kubecfg $KOPS_CLUSTER_NAME` to export `kubecfg` settings.

You need to do it every time before you work with the cluster (run `kubectl` or `kops` commands, validate cluster `kops validate cluster`, etc.) after it has been created.

<br/>


### Provision `vpc` from `backing-services` with Terraform

__NOTE:__ We provision `backing-services` in two phases because:

* `aurora-postgres` and `elasticache-redis` depend on `vpc-peering` (they use `kops` Security Group to allow `kops` applications to connect)
* `vpc-peering` depends on `vpc` and `kops` (it creates a peering connection between the two networks)

To break the circular dependencies, we provision `kops`, then `vpc` (from `backing-services`), then `vpc-peering`,
and finally the rest of `backing-services` (`aurora-postgres` and `elasticache-redis`).

__NOTE:__ We use `chamber` to first populate the environment with the secrets from the specified service (`backing-services`)
and then execute the given commands (`terraform plan` and `terraform apply`)


```bash
cd /conf/backing-services
init-terraform
chamber exec backing-services -- terraform plan -target=module.identity -target=module.vpc -target=module.subnets
chamber exec backing-services -- terraform apply -target=module.identity -target=module.vpc -target=module.subnets
```


### Provision `vpc-peering` from `kops-aws-platform` with Terraform

```bash
cd /conf/kops-aws-platform
init-terraform
terraform plan -target=module.identity -target=data.aws_vpc.backing_services_vpc -target=module.kops_vpc_peering
terraform apply -target=module.identity -target=data.aws_vpc.backing_services_vpc -target=module.kops_vpc_peering
```


### Provision the rest of `kops-aws-platform` with Terraform

```bash
cd /conf/kops-aws-platform
terraform plan
terraform apply
```


### Provision the rest of `backing-services` with Terraform

__NOTE:__ We use `chamber` to first populate the environment with the secrets from the specified service (`backing-services`)
and then execute the given commands (`terraform plan` and `terraform apply`)

```bash
cd /conf/backing-services
chamber exec backing-services -- terraform plan
chamber exec backing-services -- terraform apply
```



### Provision Kubernetes resources

We use [helmfile](https://github.com/roboll/helmfile) to deploy [Helm](https://helm.sh/) [charts](https://github.com/kubernetes/charts) to provision Kubernetes resources.

`helmfile.yaml` is located in the `/conf/kops` directory in `geodesic` container (see [helmfile.yaml](https://github.com/cloudposse/geodesic/blob/master/conf/kops/helmfile.yaml)).

Change the current directory to `kops`

```bash
cd /conf/kops
```

Deploy the Helm charts

__NOTE:__ We use `chamber` to first populate the environment with the secrets from the `kops` service and then execute the given command (`helmfile sync`)

``` bash
kops export kubecfg $KOPS_CLUSTER_NAME
chamber exec kops -- helmfile sync
```


### References

* https://docs.cloudposse.com
* https://github.com/segmentio/chamber
* https://aws.amazon.com/blogs/mt/the-right-way-to-store-secrets-using-parameter-store/
* https://github.com/kubernetes-incubator/external-dns/blob/master/docs/faq.md
* https://github.com/gravitational/workshop/blob/master/k8sprod.md

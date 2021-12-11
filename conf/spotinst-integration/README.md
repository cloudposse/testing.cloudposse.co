# Component: `spotinst-integration`

This component is responsible for provisioning the IAM policies, roles, and instance profile for integrating an account with [Spotinst](https://spot.io/).

See the [documentation on configuring Spotinst here](./spotinst-configuration.md) for full details on obtaining a Spotinst API Key and providing that to the account.

## Usage

This component cannot be installed via Atlantis because it requires multiple manual interventions. 
The procedure in [spotinst-configuration.md](./spotinst-configuration.md) 
also does not work because it assumes a late 2021 (`atmos`, stacks, etc.)
environment.

The procedure in [spotinst-manual-configuration.md](./spotinst-manual-configuration.md) 
to set up Spotinst is closer, but still not quite, because it too assumes
there is a `namespace`-gbl-`stage`-helm role to use, which we 
do not have, and it assumes we have a paid account, which we do not.

So this set up is very manual, but you can leverage the tools 
in [spotinst-manual-configuration.md](./spotinst-manual-configuration.md) to help.

Basic steps:

- Get an Admin API token for Spotinst (via the web UI) and save it in an environment variable.
- Create a Spotinst account for this AWS account (via `curl`). Except on the free plan, we can only have 1 account, 
and it has already been created.
- Create (via `curl`) a programmatic user and associated API token and save the token in SSM.
Actually, we do not need to save it in SSM, but it is handy there. 
Where it really needs to go is in a GitHub Secret as `SPOTINST_TOKEN`.
- Create an "external ID" for the Spotinst API role and save it in SSM.
- Run `terraform apply` to provision:
  - An IAM Role for Spotinst API to use to manage resources in the account
  - An IAM Role to give the EKS installed Ocean Controller the access it needs
  - An EC2 Instance Profile to assign the Ocean Controller IAM Role to an instance
- Configure (via `curl`) the Spotinst API to use the API IAM Role

When done, the Spot.io Dashboard should show that the account status is "connected".



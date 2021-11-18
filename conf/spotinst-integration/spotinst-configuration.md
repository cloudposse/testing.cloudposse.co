## Spotinst Configuration

When you sign up with Spotinst, you get an "organization" and a default "account". Spotinst needs a 1-to-1 mapping
between AWS accounts and Spotinst "accounts", so we have to create them. To keep things consistent, we do not use the
default account.

Note the account cannot be a Freemium account. It needs to be at least Basic or it will fail to programmatically create
accounts.

### Generate an API token with Admin access

As of this writing, the UI for creating a temporary token risks leaking your most valuable token, your password, so
instead we recommend creating a "permanent" token and deleting it when you are done.

As an admin user, on the web UI, navigate to `<Avatar> -> Settings -> API tab` and select "Permanent Tokens" then the +
to "GENERATE TOKEN", then "Select user type:" `Personal` and enter "Create Accounts" as the token name to create a new
permanent token.

In the Geodesic shell, save the API token as `SPOTINST_TOKEN` environment variable

```bash
export SPOTINST_TOKEN=xxxxxxxxxxxx
```

### Generate API keys for the account

We have scripts for the remaining non-terraform portions of the process. The scripts are in the folder with the
Terraform `spotinst-integration` component (likely the same folder as this file that you are reading). Our example
invocations will assume you are in the root directory where you would normally run `atmos`.

Note: The scripts take the account name, which is usually the `stage` label name for each account. If the `tenant` label
is used, then the account name is `[tenant]-[stage]`.

First, we generate an API key for the account:

```
components/terraform/spotinst-integration/setup-before-terraform <account>
```

### Run terraform

Now that we have API keys, we can run the terraform to create the IAM role:

```
atmos terraform plan spotinst-integration -s=gbl-<stage>
atmos terraform apply spotinst-integration -s=gbl-<stage>
```

### Configure the IAM role

Now configure Spotinst to use the IAM role we just created:

```
components/terraform/spotinst-integration/setup-after-terraform <account>
```

## Delete your API key

Your API key is powerful and long lived, and you are now done with it. Go to the Spotinst web site and delete your API
key.

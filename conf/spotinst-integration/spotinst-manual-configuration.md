## Spotinst Manual Configuration

### Note: Use scripted configuration if possible

See [spotinst-configuration.md](./spotinst-configuration.md)

When you sign up, you get an "organization" and a default "account". Spotinst needs a 1-to-1 mapping between AWS
accounts and Spotinst "accounts", so we have to create them. To keep things consistent, we do not use the default
account for Oceans.

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

### Create a Spotinst account for each AWS EKS account

Unfortunately, you can create as many Spotinst accounts with the same name as you want. So first check if an account
already exists:

```bash
acct=<account-name>
curl -sSL --header "Authorization: Bearer $SPOTINST_TOKEN" \
  'https://api.spotinst.io/setup/account' | \
  jq '.response.items[] | select(.name == "'$acct'")'
```

If there is more than one account, delete extra accounts. Copy the `accountId` and run:

```bash
curl -sSL --header "Authorization: Bearer $SPOTINST_TOKEN" --request DELETE \
  'https://api.spotinst.io/setup/account'/$accountId
```

For each AWS account that will have an EKS cluster:

```bash
for acct in <account-list>; do
    curl -sS --location --request POST 'https://api.spotinst.io/setup/account' \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $SPOTINST_TOKEN" \
    --data-raw '{
        "account": {
            "name": "'$acct'"
        }
    }' -o $acct && \
    AWS_PROFILE=${namespace}-gbl-${acct}-helm chamber write spotinst spotinst_account $(jq < $acct -r '.response.items[0].id') && \
    jq < $acct -r '.response.items[0]' || break
done
```

### Create an API token for each account

For each AWS account with an EKS cluster, create a programmatic user (API token). Save the `user_id` because you need it
to operate on the user and it is difficult to retrieve otherwise. (The `sleep` is because there is a small delay between
the time you create a secret and the time it is readable.) Note, to retrieve all programmatic users, use
`curl -sSL --header "Authorization: Bearer $SPOTINST_TOKEN" 'https://api.spotinst.io/setup/user/programmatic' `

```bash
set -o pipefail
file="/tmp/${acct}-user"
accountId=$(AWS_PROFILE=${namespace}-gbl-${acct}-helm chamber read -q spotinst spotinst_account) && \
AWS_PROFILE=${namespace}-gbl-${acct}-helm chamber write spotinst spotinst_token $( \
curl -sSL --request POST 'https://api.spotinst.io/setup/user/programmatic' \
--header 'Content-Type: application/json' \
    --header "Authorization: Bearer $SPOTINST_TOKEN" \
--data-raw '{
    "name": "terraform-'$acct'",
    "description": "Terraform access for '$acct' account",
    "accounts": [{"id": "'$accountId'","role": "editor"}]
}' | tee "$file"| jq -r '.response.items[0].token') && \
sleep 2 && \
AWS_PROFILE=${namespace}-gbl-${acct}-helm chamber read -q spotinst spotinst_token | colrm 3 60 && \
AWS_PROFILE=${namespace}-gbl-${acct}-helm chamber write spotinst user_id \
  $(jq <"$file" -r '.response.items[0].id') && \
  rm -f "$file"
set +o pipefail

```

### Create an "external ID" for each account

For security, each account needs to share another secret with Spotinst, called an "external ID". This secret is required
for Spotinst to assume the IAM role in the AWS account, and mitigates against another Spotinst customer using Spotinst
to access our AWS account.

For each account:

```bash
AWS_PROFILE=${namespace}-gbl-${acct}-helm chamber write spotinst external_id -- \
  "$(dd if=/dev/random bs=32 count=1 2>/dev/null | base64 | colrm 40)"
```

### Use the Terraform `spotinst-integration` component to provision IAM role for Spotinst

For every AWS account with an EKS cluster, use the `terraform/spotinst-integration` to provision an AWS IAM role for
Spotinst.

### Configure Spotinst to use the IAM role created for it

For every AWS account with an EKS cluster, configure the corresponding Spotinst account with the IAM role and "external
ID" it needs:

```bash
accountId=$(AWS_PROFILE=${namespace}-gbl-${acct}-helm chamber read -q spotinst spotinst_account) && \
externalId=$(AWS_PROFILE=${namespace}-gbl-${acct}-helm chamber read -q spotinst external_id) && \
  curl -sSL --request POST 'https://api.spotinst.io/setup/credentials/aws?accountId='"$accountId" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $SPOTINST_TOKEN" \
  --data-raw '{
    "credentials": {
    "iamRole": "'"arn:aws:iam::$(aws-accounts $acct | cut -d' ' -f 2):role/${namespace}-gbl-${acct}-spotinst-api"'",
    "externalId": "'$externalId'"
  }
}'
```

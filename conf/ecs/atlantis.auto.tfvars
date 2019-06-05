# Write the atlantis_gh_token to SSM parameter store:
# chamber write atlantis atlantis_gh_token "....."

# When using Cognito authentication (atlantis_authentication_type = COGNITO), write the following values to SSM parameter store:
# chamber write atlantis atlantis_cognito_user_pool_arn "....."
# chamber write atlantis atlantis_cognito_user_pool_client_id "....."
# chamber write atlantis atlantis_cognito_user_pool_domain "....."

# When using OIDC authentication (atlantis_authentication_type = OIDC), write the following values to SSM parameter store:
# chamber write atlantis atlantis_oidc_client_id "....."
# chamber write atlantis atlantis_oidc_client_secret "....."

atlantis_enabled = "true"

atlantis_branch = "master"

atlantis_repo_name = "testing.cloudposse.co"

atlantis_repo_owner = "cloudposse"

atlantis_repo_whitelist = ["github.com/cloudposse/testing.cloudposse.co"]

atlantis_allow_repo_config = "true"

atlantis_repo_config = "/conf/ecs/atlantis-repo-config.yaml"

atlantis_gh_user = "cloudpossebot"

atlantis_gh_team_whitelist = "cloudposse:*,engineering:*"

atlantis_authentication_type = "OIDC"

atlantis_oidc_issuer = "https://accounts.google.com"

atlantis_oidc_authorization_endpoint = "https://accounts.google.com/o/oauth2/v2/auth"

atlantis_oidc_token_endpoint = "https://oauth2.googleapis.com/token"

atlantis_oidc_user_info_endpoint = "https://openidconnect.googleapis.com/v1/userinfo"

atlantis_alb_ingress_unauthenticated_paths = ["/events"]

atlantis_alb_ingress_listener_unauthenticated_priority = "50"

atlantis_alb_ingress_authenticated_paths = ["/*"]

atlantis_alb_ingress_listener_authenticated_priority = "100"

region = "us-west-2"

availability_zones = ["us-west-2a", "us-west-2b"]

nat_gateway_enabled = "false"

nat_instance_enabled = "true"

nat_instance_type = "t3.micro"

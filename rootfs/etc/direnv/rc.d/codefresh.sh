function use_codefresh() {
	if [ -z "${CHAMBER_KMS_KEY_ALIAS}" ]; then
		echo "WARN: CHAMBER_KMS_KEY_ALIAS is not set"
	fi

	# Download plugins to /var/lib/cache to speed up applies
	export TF_PLUGIN_CACHE_DIR=${TF_PLUGIN_CACHE_DIR:-/var/lib/terraform}

	if [ -n "${TF_LOG}" ]; then
		echo "WARN: TF_LOG is set which may expose secrets"
	fi

	# Disable prompts for variables that haven't had their values specified
	export TF_INPUT=false

	# Disable color on all terraform commands
	export TF_CLI_DEFAULT_NO_COLOR=true

	# Auto approve apply
	export TF_CLI_APPLY_AUTO_APPROVE=true

	# Disable color terminals (direnv)
	export TERM=dumb

	# Export environment from chamber to shell
	source <(chamber exec atlantis -- sh -c "export -p")

	if [ -n "${ATLANTIS_IAM_ROLE_ARN}" ]; then
		# Map the Atlantis IAM Role ARN to the env we use everywhere in our root modules
		export TF_VAR_aws_assume_role_arn=${ATLANTIS_IAM_ROLE_ARN}
	fi

	# Add SSH key to agent, if one is configured so we can pull from private git repos
	if [ -n "${ATLANTIS_SSH_PRIVATE_KEY}" ]; then
		source <(ssh-agent -s)
		ssh-add - <<<${ATLANTIS_SSH_PRIVATE_KEY}
		# Sanitize environment
		unset ATLANTIS_SSH_PRIVATE_KEY
	fi

	# Do not export these as Terraform environment variables

	export TFENV_BLACKLIST="^(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SECURITY_TOKEN|AWS_SESSION_TOKEN|ATLANTIS_.*|GITHUB_.*)$"
}

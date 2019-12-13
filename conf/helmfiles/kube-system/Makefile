deps: .helmfile/cache

.helmfile/cache:
	helmfile deps

diff: .helmfile/cache
	helmfile diff --suppress-secrets --skip-deps --args="--allow-unreleased --context 5 --no-color"

apply: .helmfile/cache
  # Until helmfile apply supports --no-color Strip color from output using sed
  # From https://www.commandlinefu.com/commands/view/3584/remove-color-codes-special-characters-with-sed
	helmfile apply --suppress-secrets --skip-deps | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"

## Reset this project
reset:
	rm -rf releases scripts .helmfile/cache
	exit 0

## Install or upgrade tiller.
install-tiller upgrade-tiller: kubeconfig
	helm init --override 'spec.template.metadata.annotations.cluster-autoscaler\.kubernetes\.io/safe-to-evict=true' --history-max 200 --upgrade 

.PHONY: kubeconfig
kubeconfig:
	chamber exec kops -- kops export kubecfg

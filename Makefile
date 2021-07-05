export CLUSTER ?= testing.cloudposse.co
export DOCKER_ORG ?= cloudposse
export DOCKER_IMAGE ?= $(DOCKER_ORG)/$(CLUSTER)
export DOCKER_TAG ?= latest
export DOCKER_IMAGE_NAME ?= $(DOCKER_IMAGE):$(DOCKER_TAG)
#export DOCKER_BUILD_FLAGS = --pull
export README_DEPS ?= docs/targets.md docs/terraform.md
export INSTALL_PATH ?= /usr/local/bin
export SCRIPT ?= $(notdir $(DOCKER_IMAGE))

-include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)

## Initialize build-harness, install deps, build docker container, install wrapper script and run shell
all: init deps build install run
	@exit 0

## Install dependencies (if any)
deps:
	@exit 0

## Build docker image
build:
	@make --no-print-directory docker/build

## Push docker image to registry
push:
	docker push $(DOCKER_IMAGE)

## Install wrapper script from geodesic container
install:
	@docker run --rm $(DOCKER_IMAGE_NAME) | bash -s $(DOCKER_TAG) || \
	  echo '"make install" failed, try "sudo make instal"' >&2

## Start the geodesic shell by calling wrapper script
run:
	$(SCRIPT)

nuke:
	docker run -it -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -v $(CURDIR)/.github:/.github quay.io/rebuy/aws-nuke:v2.15.0-beta.1 --config /.github/aws-nuke.yaml --force --no-dry-run

nuke-dryrun:
	docker run -it -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -v $(CURDIR)/.github:/.github quay.io/rebuy/aws-nuke:v2.15.0-beta.1 --config /.github/aws-nuke.yaml --force --force-sleep=3

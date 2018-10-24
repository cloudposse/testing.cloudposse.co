PLANFILE ?= terraform.tfplan

init:
	@[ -d .terragrunt-cache ] || terragrunt init -no-color

plan: init
	chamber exec atlantis github -- terragrunt plan -out $(PLANFILE)

apply:
	chamber exec atlantis github -- terragrunt apply -auto-approve=true $(PLANFILE)

destroy:
	chamber exec atlantis github -- terragrunt destroy -auto-approve=true


clean:
	rm -rf .terragrunt-cache/


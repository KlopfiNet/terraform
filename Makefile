.PHONY: prepare

prepare:
	@echo "Checking if files exist..."
	@test -e secret.tfvars || (echo "Error: secret-tfvars does not exist." && exit 1)

plan: prepare
	terraform plan --var-file=secret.tfvars

apply: prepare
	terraform apply -auto-approve --var-file=secret.tfvars
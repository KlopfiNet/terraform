.PHONY: prepare

prepare:
	@echo "Checking if files exist..."
	@test -e secret.tfvars || (echo "Error: secret-tfvars does not exist." && exit 1)

plan: prepare
	terraform plan --var-file=secret.tfvars

apply: prepare
	terraform apply -auto-approve --var-file=secret.tfvars

extract-configs:
	@echo "Extracting kubeconfig and talosconfig..."
	@eval terraform output -json | jq .kubernetes.value.talos_kubeconfig -r > $$HOME/.kube/config
	@eval terraform output -json | jq .kubernetes.value.talos_machine_config -r > $$HOME/.talos/config
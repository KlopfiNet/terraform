# terraform-kubernetes
Repo contains IaC code to bootstrap kubernetes node machines.

Built for Proxmox `8.1.3`.

## Usage
1. Copy `.env.example` to `.env` and adjust.
2. `source .env`
3. Create `secret.tfvars`:
```hcl
pve_password = ""
```

4. Initialize:
```bash
terraform init #-backend-config=backend.conf
```

5. (Optional) Prepare a few env vars:
```bash
export TF_LOG="" # Set to DEBUG if need be
export VAULT_ADDR="http://10.0.1.152:8200"
export VAULT_TOKEN="..."
```

6. Execute:
```bash
make plan
make apply # Caution: auto-approve
```

### Talos
```bash
# Get talos config
terraform output -json | jq .kubernetes.value.talos_machine_config -r > $HOME/.talos/config

# Get talos kubeconfig
terraform output -json | jq .kubernetes.value.talos_kubeconfig -r > $HOME/.kube/config

# Get talos nodes (e.g. for talosctl health --endpoints ...)
terraform output -json | jq .kubernetes.value.talos_nodes

# Get talos image data (debugging)
terraform output -json | jq .kubernetes.value.talos_image_data
terraform output -json | jq .kubernetes.value.talos_image_data.talos_image_factory_schematic.schematic -r
```

### CI
Upon inventory generation, a CI action will attempt to upload the new inventory into the ansible repo.  
For caching purposes, the runners are expected to have a `/cache` directory mounted.  
Attempts to get S3 or GH cache targets to work have been in vain.
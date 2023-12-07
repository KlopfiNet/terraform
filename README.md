# terraform-kubernetes
Repo contains IaC code to bootstrap kubernetes node machines.

Built for Proxmox `8.1.3`.

## Usage
Set S3 env vars, or store in `secret.env`:
```bash
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""

# Keyname should be fully qualified, therefore <name>. (dot at end)
export DNS_UPDATE_KEYNAME=""
export DNS_UPDATE_KEYSECRET=$(echo "..." | base64) # <- must be base64 encoded
export DNS_UPDATE_KEYALGORITHM="hmac-sha256"

export MINIO_USER=""
export MINIO_PASSWORD=""

# If stored in secret.env
set -o allexport && source secret.env && set +o allexport
```

Create `secret.tfvars`:
```hcl
pve_password = ""
```

Initialize:
```bash
terraform init #-backend-config=backend.conf
```

(Optional) Prepare a few env vars:
```bash
export TF_LOG="" # Set to DEBUG if need be
export VAULT_ADDR="http://10.0.1.152:8200"
export VAULT_TOKEN="..."
```
terraform {
  required_providers {
    # Redefined in kubernetes module!
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.70.0"
    }
  }

  required_version = ">= 1.6"
}

provider "proxmox" {
  endpoint = "https://10.0.1.10:8006/"
  insecure = true
  tmp_dir  = "/var/tmp"

  # Expected format: <user>@<node>!<token_name>=<token_secret>
  # Does not work for kvm_args because bullshit
  #api_token = "${data.vault_generic_secret.pm_api_token_id.data["value"]}=${data.vault_generic_secret.pm_api_token_secret.data["value"]}"

  # This is required, see above
  username = "${var.pve_user}@pam"
  password = var.pve_password

  ssh {
    # Required for certain actions that are not possible with just the API alone
    username = var.pve_user
    agent    = true
  }
}

# -------------------------------------------

terraform {
  backend "s3" {
    bucket = "terraform"
    key    = "klopfi-net.tfstate"

    # Irrelevant but required
    region = "main"

    endpoints = { s3 = "https://minio.klopfi.net:9000" }

    # All required for custom S3
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true

    use_path_style = true
  }
}

# -------------------------------------------

locals {
  ssh_pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEch+fpr62X3Lb4qvEREysIHnhB6nrdZKbzWF/OSIri ansible"
}

# -------------------------------------------
# MODULES

# MinIO
module "minio" {
  # For credentials, set env vars: MINIO_USER, SECOND_MINIO_PASSWORD
  source = "./modules/minio"

  buckets = [
    "velero",
    "gh-artifacts"
  ]
}

# Kuberenetes
module "kubernetes" {
  source = "./modules/kubernetes"

  talos_version = "v1.9.1"

  nodes = [
    {
      role  = "master"
      count = 1
    }
  ]

  # Node sizing
  node_master_cpu_sockets = 1
  node_master_cpu_cores   = 2
  node_master_memory      = 4096

  node_worker_cpu_sockets = 1
  node_worker_cpu_cores   = 2
  node_worker_memory      = 7168

  node_infra_cpu_sockets = 1
  node_infra_cpu_cores   = 2
  node_infra_memory      = 7168
}

# -------------------------------------------
output "kubernetes" {
  value     = module.kubernetes
  sensitive = true
}

output "minio" {
  value     = module.minio
  sensitive = true
}

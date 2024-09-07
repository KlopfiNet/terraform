terraform {
  required_version = ">= 1.6"

  # Keep in line with ./common/proxmox-config.tf!
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.63.0"
    }
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

locals {
  ssh_pub      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEch+fpr62X3Lb4qvEREysIHnhB6nrdZKbzWF/OSIri ansible"
  pve_password = var.pve_password
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
module "kube_machine" {
  source = "./modules/kube_machine"

  nodes = {
    master = {
      count = 3
      resources = {
        sockets = 1
        cores   = 2
        memory  = 4096
      }
    }
    worker = {
      count = 3
      resources = {
        sockets = 1
        cores   = 2
        memory  = 7168
      }
    }
    infra = {
      count = 1
      resources = {
        sockets = 1
        cores   = 2
        memory  = 7168
      }
    }
  }

  vm_template_id = 1010
  node_ssh_key   = local.ssh_pub
}

# Load balancer
module "load_balancer" {
  source = "./modules/load_balancer"

  vm_cpu_cores  = 1
  vm_memory     = 512
  vm_ip_address = "10.0.1.84"
  vm_ssh_key    = local.ssh_pub
  vm_id         = 300
}

# -------------------------------------------

output "kube_machine" {
  value     = module.kube_machine
  sensitive = true
}

output "load_balancer" {
  value     = module.load_balancer
  sensitive = true
}

output "minio" {
  value     = module.minio
  sensitive = true
}

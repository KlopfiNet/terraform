terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
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
module "kube_machine" {
  source = "./modules/kube_machine"

  nodes = [
    {
      name     = "kubernetes-master-01"
      ip_octet = 80
      vm_id    = 900
      role     = "master"
    },
    {
      name     = "kubernetes-master-02"
      ip_octet = 81
      vm_id    = 901
      role     = "master"
    },
    {
      name     = "kubernetes-master-03"
      ip_octet = 82
      vm_id    = 902
      role     = "master"
    },
    {
      name     = "kubernetes-worker-01"
      ip_octet = 85
      vm_id    = 910
      role     = "worker"
    },
    {
      name     = "kubernetes-worker-02"
      ip_octet = 86
      vm_id    = 911
      role     = "worker"
    },
    {
      name     = "kubernetes-infra-01"
      ip_octet = 90
      vm_id    = 920
      role     = "infra"
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

  node_ssh_key = local.ssh_pub
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

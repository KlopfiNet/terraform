terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
  }
}

provider "proxmox" {
  endpoint = "https://10.0.1.10:8006/"
  insecure = true
  tmp_dir  = "/var/tmp"

  // Expected format: <user>@<node>!<token_name>=<token_secret>
  // Does not work for kvm_args because bullshit
  //api_token = "${data.vault_generic_secret.pm_api_token_id.data["value"]}=${data.vault_generic_secret.pm_api_token_secret.data["value"]}"

  // This is required, see above
  username = "${var.pve_user}@pam"
  password = var.pve_password

  ssh {
    // Required for certain actions that are not possible with just the API alone
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

# Kuberenetes
module "kube-machine" {
  source = "./modules/kube-machine"

  // Vars here
  nodes = [
    {
      name     = "kubernetes-master-01"
      ip_octet = 80
      vm_id    = 900
      master   = true
    },
    {
      name     = "kubernetes-master-02"
      ip_octet = 81
      vm_id    = 901
      master   = true
    },
    {
      name     = "kubernetes-master-03"
      ip_octet = 82
      vm_id    = 902
      master   = true
    },
    {
      name     = "kubernetes-worker-01"
      ip_octet = 85
      vm_id    = 910
      master   = false
    }
  ]

  node_cpu_sockets = 1
  node_cpu_cores   = 1
  node_memory      = 3072
  node_ssh_key     = local.ssh_pub
}

# Load balancer
module "load-balancer" {
  source = "./modules/load-balancer"

  vm_cpu_cores  = 1
  vm_memory     = 512
  vm_ip_address = "10.0.1.84"
  vm_ssh_key    = local.ssh_pub
  vm_id         = 300
}

# -------------------------------------------

output "kube-machine" {
  value     = module.kube-machine
  sensitive = true
}

output "load-balancer" {
  value     = module.load-balancer
  sensitive = true
}
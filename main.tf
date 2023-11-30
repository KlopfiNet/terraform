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
locals {
  ssh_pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEch+fpr62X3Lb4qvEREysIHnhB6nrdZKbzWF/OSIri ansible"
}

# -------------------------------------------

# Kuberenetes
module "machine" {
  source = "./modules/kube-machine"

  // Vars here
  nodes = [
    {
      name     = "kubernetes-master-01"
      ip_octet = 80
      vm_id    = 900
    },
    {
      name     = "kubernetes-master-02"
      ip_octet = 81
      vm_id    = 901
    },
    {
      name     = "kubernetes-master-03"
      ip_octet = 82
      vm_id    = 902
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

  lxc_cpu_cores  = 1
  lxc_memory     = 512
  lxc_ip_address = "10.0.1.84"
  lxc_template   = "debian-12-standard_12.2-1_amd64.tar.zst"
  lxc_ssh_key    = local.ssh_pub
  lxc_vm_id      = 300
}
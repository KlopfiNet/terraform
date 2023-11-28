terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
  }
}

provider "vault" {
  address = "http://10.0.1.152:8200"
  #token = VAULT_TOKEN ENV VAR
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

module "machine" {
  source = "./modules/machine"

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
}
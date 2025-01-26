terraform {
  required_providers {
    # Redefined due to TF quirk. Not doing so results in TF trying to get 'hashicorp/proxmox.
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.3.2"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
  }
}
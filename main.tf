terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=2.9.14"
    }
  }
}

provider "vault" {
  address = "http://10.0.1.152:8200"
  #token = VAULT_TOKEN ENV VAR
}

data "vault_generic_secret" "pm_api_token_id" {
  path = "secret/proxmox/api_token_id"
}

data "vault_generic_secret" "pm_api_token_secret" {
  path = "secret/proxmox/api_token_secret"
}

provider "proxmox" {
  pm_tls_insecure     = true
  pm_api_url          = "https://10.0.1.10:8006/api2/json"
  pm_api_token_id     = data.vault_generic_secret.pm_api_token_id.data["value"]
  pm_api_token_secret = data.vault_generic_secret.pm_api_token_secret.data["value"]
}

// Reference the modules/rancher-mgmt module
module "rancher_mgmt" {
  source = "./modules/rancher-mgmt"

  cluster_name = "rancher"
  cluster_fqdn = "rancher.klofpi.net"

  rancher_master_nodes = [
    {
      name = "rancher-master-01"
      ip   = 2
    },
    {
      name = "rancher-master-02"
      ip   = 3
    },
    {
      name = "rancher-master-03"
      ip   = 4
    }
  ]
}
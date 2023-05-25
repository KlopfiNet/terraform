terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=2.9.14"
    }
  }
}

data "vault_generic_secret" "pm_api_token_id" {
  path = "secret/proxmox/api_token_id"
}

data "vault_generic_secret" "pm_api_token_secret" {
  path = "secret/proxmox/api_token_secret"
}

provider "proxmox" {
    pm_tls_insecure = true
    pm_api_url = "https://pvx.host:8006/api2/json"
    pm_api_token_id = data.vault_generic_secret.pm_api_token_id["value"]
    pm_api_token_secret = data.vault_generic_secret.pm_api_token_secret["value"]
}
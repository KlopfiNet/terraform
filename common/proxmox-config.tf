terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.63.0"
    }
  }
}

variable "pve_node_name" {
  description = "Name of the pve node"
  type        = string
  default     = "hv"
}

variable "pve_datastore_data" {
  description = "Name of pve datastore to store snippets and ISOs inside"
  type        = string
  default     = "local"
}

variable "pve_datastore_vm" {
  description = "Name of pve datastore to store VMs inside"
  type        = string
  default     = "vms"
}

variable "pve_snippets_pwd" {
  description = "Location of where snippets are stored on the node. Do not provide a / at the end."
  type        = string
  default     = "/var/lib/vz/snippets"

  validation {
    condition     = length(regexall("/$", var.pve_snippets_pwd)) == 0
    error_message = "The variable should not end with a forward slash."
  }
}

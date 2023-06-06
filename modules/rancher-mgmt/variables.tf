variable "cluster_name" {
  description = "The name to use for the cluster."
  type        = string
}

variable "cluster_fqdn" {
  description = "The FQDN that the cluster will use."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+([\\-\\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}$", var.cluster_fqdn))
    error_message = "The cluster FQDN must be a valid domain name."
  }
}

variable "rancher_master_nodes" {
  description = "Master node configuration set."
  type = list(object({
    name = string,
    ip   = number
  }))

  // Validate that name is unique
  validation {
    condition     = length(var.rancher_master_nodes) == length(distinct([for n in var.rancher_master_nodes : n.name]))
    error_message = "The master node name must be unique."
  }

  // Validate that ip is a number between 2 and 25
  validation {
    condition     = alltrue([for n in var.rancher_master_nodes : n.ip > 1 && n.ip < 255])
    error_message = "The master node IP must be a number between 2 and 254."
  }
}
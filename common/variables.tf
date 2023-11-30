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

// -------------------------------

variable "nodes" {
  description = "Master node configuration set."
  type = list(object({
    name     = string,
    ip_octet = number,
    vm_id    = number
  }))

  // Validate that name is unique
  validation {
    condition     = length(var.nodes) == length(distinct([for n in var.nodes : n.name]))
    error_message = "The master node name must be unique."
  }

  // Validate that ip_octet is a number between 2 and 25
  validation {
    condition     = alltrue([for n in var.nodes : n.ip_octet > 1 && n.ip_octet < 255])
    error_message = "The master node ip_octet must be a number between 2 and 254."
  }


  // Validate VM vm_id
  validation {
    condition     = alltrue([for n in var.nodes : n.vm_id >= 900 && n.vm_id <= 1000])
    error_message = "The VM vm_id must be a number between 900 and 1000."
  }

  // Validate that the list has an uneven amount of entries (etcd)
  validation {
    condition     = length(var.nodes) % 2 == 1
    error_message = "Must provide an uneven amount of master nodes"
  }
}

variable "node_memory" {
  description = "Amount of memory to allocate for EACH master node. Provide in sizes of 1024."
  type        = number

  validation {
    condition     = var.node_memory >= 3072
    error_message = "Must provide at least 3GB (3072MB) of memory"
  }
}

variable "node_cpu_cores" {
  description = "Amount of CPU cores to allocate for EACH master node."
  type        = number
}

variable "node_cpu_sockets" {
  description = "Amount of CPU sockets to allocate for EACH master node."
  type        = number
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.27.4"
}
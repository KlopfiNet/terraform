variable "nodes" {
  description = "node configuration set."
  type = list(object({
    role  = string,
    count = number
  }))

  // Check that role is of an authorized list
  validation {
    condition     = alltrue([for node in var.nodes : contains(["controlplane", "worker", "infra"], node.role)])
    error_message = "Non-accepted machine role provided."
  }

  // ----- controlplane node validations
  // Check for an uneven amount of controlplanes
  // sum() is used, as the for[] can include true and false entries
  validation {
    condition     = sum([for n in var.nodes : n.role == "controlplane" ? 1 : 0]) % 2 == 1
    error_message = "Must provide an uneven amount of controlplane nodes"
  }

  // Check that at least one controlplane has been defined
  validation {
    condition     = length([for n in var.nodes : n.role == "controlplane"]) >= 1
    error_message = "No controlplane node has been provided"
  }
}

// ------------ controlplane
variable "node_controlplane_memory" {
  description = "Amount of memory to allocate for controlplane nodes. Provide in sizes of 1024."
  type        = number

  validation {
    condition     = var.node_controlplane_memory >= 3072
    error_message = "Must provide at least 3GB (3072MB) of memory"
  }
}

variable "node_controlplane_cpu_cores" {
  description = "Amount of CPU cores to allocate for controlplane nodes."
  type        = number
}

variable "node_controlplane_cpu_sockets" {
  description = "Amount of CPU sockets to allocate for controlplane nodes."
  type        = number
}

// ------------ WORKER
variable "node_worker_memory" {
  description = "Amount of memory to allocate for worker nodes. Provide in sizes of 1024."
  type        = number

  validation {
    condition     = var.node_worker_memory >= 3072
    error_message = "Must provide at least 3GB (3072MB) of memory"
  }
}

variable "node_worker_cpu_cores" {
  description = "Amount of CPU cores to allocate for worker nodes."
  type        = number
}

variable "node_worker_cpu_sockets" {
  description = "Amount of CPU sockets to allocate for worker nodes."
  type        = number
}

// ------------ INFRA
variable "node_infra_memory" {
  description = "Amount of memory to allocate for infra nodes. Provide in sizes of 1024."
  type        = number

  validation {
    condition     = var.node_infra_memory >= 3072
    error_message = "Must provide at least 3GB (3072MB) of memory"
  }
}

variable "node_infra_cpu_cores" {
  description = "Amount of CPU cores to allocate for infra nodes."
  type        = number
}

variable "node_infra_cpu_sockets" {
  description = "Amount of CPU sockets to allocate for infra nodes."
  type        = number
}

variable "talos_version" {
  description = "Talos version"
  default     = "v1.9.2"
  type        = string
}
variable "kubernetes_version" {
  description = "Kubernetes version"
  default     = "v1.32.0"
  type        = string
}

// ---------------------------
/*
variable "node_ssh_key" {
  description = "SSH pub of key to use for user account."
  type        = string
}

variable "vm_image_url" {
  description = "URL of VM image."
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  #"https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
}
*/
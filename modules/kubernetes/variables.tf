variable "nodes" {
  description = "node configuration set."
  type = list(object({
    role  = string,
    count = number
  }))

  // Check that role is of an authorized list
  validation {
    condition     = alltrue([for node in var.nodes : contains(["master", "worker", "infra"], node.role)])
    error_message = "Non-accepted machine role provided."
  }

  // ----- Master node validations
  // Check for an uneven amount of masters
  // sum() is used, as the for[] can include true and false entries
  validation {
    condition     = sum([for n in var.nodes : n.role == "master" ? 1 : 0]) % 2 == 1
    error_message = "Must provide an uneven amount of master nodes"
  }

  // Check that at least one master has been defined
  validation {
    condition     = length([for n in var.nodes : n.role == "master"]) >= 1
    error_message = "No master node has been provided"
  }
}

// ------------ MASTER
variable "node_master_memory" {
  description = "Amount of memory to allocate for master nodes. Provide in sizes of 1024."
  type        = number

  validation {
    condition     = var.node_master_memory >= 3072
    error_message = "Must provide at least 3GB (3072MB) of memory"
  }
}

variable "node_master_cpu_cores" {
  description = "Amount of CPU cores to allocate for master nodes."
  type        = number
}

variable "node_master_cpu_sockets" {
  description = "Amount of CPU sockets to allocate for master nodes."
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
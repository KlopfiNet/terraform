variable "nodes" {
  description = "node configuration set."
  type = list(object({
    name     = string,
    ip_octet = number,
    vm_id    = number,
    master   = bool,
  }))

  // Validate that name is unique
  validation {
    condition     = length(var.nodes) == length(distinct([for n in var.nodes : n.name]))
    error_message = "The node name must be unique."
  }

  // Validate that ip_octet is a number between 2 and 25
  validation {
    condition     = alltrue([for n in var.nodes : n.ip_octet > 1 && n.ip_octet < 255])
    error_message = "The node ip_octet must be a number between 2 and 254."
  }


  // Validate VM vm_id
  validation {
    condition     = alltrue([for n in var.nodes : n.vm_id >= 900 && n.vm_id <= 1000])
    error_message = "The VM vm_id must be a number between 900 and 1000."
  }

  // Validate that the list has an uneven amount of masters (etcd)
  validation {
    condition     = length([for obj in var.nodes : obj.master if obj.master]) % 2 == 1
    error_message = "Must provide an uneven amount of nodes"
  }
}

variable "node_memory" {
  description = "Amount of memory to allocate for EACH node. Provide in sizes of 1024."
  type        = number

  validation {
    condition     = var.node_memory >= 3072
    error_message = "Must provide at least 3GB (3072MB) of memory"
  }
}

variable "node_cpu_cores" {
  description = "Amount of CPU cores to allocate for EACH node."
  type        = number
}

variable "node_cpu_sockets" {
  description = "Amount of CPU sockets to allocate for EACH node."
  type        = number
}

variable "node_ssh_key" {
  description = "SSH pub of key to use for user account."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.27.4"
}

variable "vm_image_url" {
  description = "URL of VM image."
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  #"https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
}
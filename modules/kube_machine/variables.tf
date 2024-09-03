variable "nodes" {
  type = map(object({
    count = number
    resources = object({
      sockets = number
      cores   = number
      memory  = number
    })
  }))
}

// ---------------------------

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
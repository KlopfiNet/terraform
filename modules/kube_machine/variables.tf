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

variable "vm_template_id" {
  description = "ID of template to clone VM with."
  type        = number
}
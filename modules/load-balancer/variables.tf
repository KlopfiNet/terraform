variable "lxc_memory" {
  description = "Amount of memory to allocate for container. Provide in sizes of 1024."
  type        = number

  validation {
    condition     = var.lxc_memory >= 512
    error_message = "Must provide at least 512MB of memory"
  }
}

variable "lxc_cpu_cores" {
  description = "Amount of CPU cores to allocate for container."
  type        = number
}

variable "lxc_cpu_units" {
  description = "Amount of CPU units to allocate for container."
  type        = number
  default     = 1024
}

variable "lxc_vm_id" {
  description = "ID of container."
  type        = number
}

variable "lxc_ip_address" {
  description = "IPv4 address of the container."
  type        = string

  validation {
    condition     = can(regex("^\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b$", var.lxc_ip_address))
    error_message = "Invalid IP address format. Please provide a valid IPv4 address."
  }
}

variable "lxc_template" {
  # See: http://download.proxmox.com/images/system/
  description = "Filename of the template as provided by proxmox repo."
  type        = string
}

variable "lxc_template_type" {
  description = "Type of the lxc template."
  type        = string
  default     = "debain"
}

variable "lxc_ssh_key" {
  description = "SSH pub of key to use for user account."
  type        = string
}
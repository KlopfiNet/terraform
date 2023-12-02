variable "vm_memory" {
  description = "Amount of memory to allocate for vm. Provide in sizes of 1024."
  type        = number

  validation {
    condition     = var.vm_memory >= 512
    error_message = "Must provide at least 512MB of memory"
  }
}

variable "vm_cpu_cores" {
  description = "Amount of CPU cores to allocate for vm."
  type        = number
}

variable "vm_cpu_sockets" {
  description = "Amount of CPU sockets to allocate for vm."
  type        = number
  default     = 1
}

variable "vm_id" {
  description = "ID of vm."
  type        = number
}

variable "vm_ip_address" {
  description = "IPv4 address of the vm."
  type        = string

  validation {
    condition     = can(regex("^\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b$", var.vm_ip_address))
    error_message = "Invalid IP address format. Please provide a valid IPv4 address."
  }
}

variable "vm_disk_size" {
  description = "Disk size of the vm."
  type        = number
  default     = 10
}

variable "vm_ssh_key" {
  description = "SSH pub of key to use for user account."
  type        = string
}

variable "vm_image_url" {
  description = "URL of VM image."
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  #default     = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}
variable "pve_user" {
  description = "Name of pve user to connect to over API and SSH"
  type        = string
  default     = "root"
}

variable "pve_password" {
  description = "Password of pve user to connect to over API and SSH"
  type        = string
}
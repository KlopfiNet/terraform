terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
  }
}

locals {
  container_network_address = join(".", slice(split(".", var.lxc_ip_address), 0, 3))
  # Last octet and . are removed, e.g.: 10.0.1.50 -> 10.0.1

  container_gateway_last_octet = 1
  container_ipv4_cidr          = 24
}

resource "random_password" "container_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "proxmox_virtual_environment_file" "lxc_template" {
  content_type = "vztmpl"
  datastore_id = var.pve_datastore_data
  node_name    = var.pve_node_name

  source_file {
    path = "http://download.proxmox.com/images/system/${var.lxc_template}"
  }
}

resource "proxmox_virtual_environment_container" "load_balancer" {
  description = "Managed by Terraform"
  node_name   = var.pve_node_name
  vm_id       = var.lxc_vm_id

  tags = [
    "debain",
    "load-balancer",
    "terraform"
  ]

  initialization {
    hostname = "kubernetes-lb"

    ip_config {
      ipv4 {
        address = "${var.lxc_ip_address}/${local.container_ipv4_cidr}"
        gateway = "${local.container_network_address}.${local.container_gateway_last_octet}"
      }
    }

    user_account {
      keys     = [trimspace(var.lxc_ssh_key)]
      password = random_password.container_password.result
    }
  }

  network_interface {
    name = "veth0"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_file.lxc_template.id
    type             = var.lxc_template_type
  }

  disk {
    datastore_id = var.pve_datastore_vm
    size         = var.lxc_disk_size
  }

  memory {
    dedicated = var.lxc_memory
  }

  cpu {
    cores = var.lxc_cpu_cores
    units = var.lxc_cpu_units
  }
}
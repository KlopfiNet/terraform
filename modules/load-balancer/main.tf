terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
  }
}

locals {
  vm_network_address = join(".", slice(split(".", var.vm_ip_address), 0, 3))
  # Last octet and . are removed, e.g.: 10.0.1.50 -> 10.0.1

  vm_gateway_last_octet = 1
  vm_ipv4_cidr          = 24
  vm_name               = "kubernetes-lb"
}

resource "random_password" "vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = var.pve_datastore_data
  node_name    = var.pve_node_name

  source_raw {
    data = templatefile("${path.module}/templates/cloud_config.tmpl", {
      ssh_key    = var.vm_ssh_key
      hostname   = local.vm_name
      password   = random_password.vm_password.result
    })

    file_name = "cloud_config-${var.vm_id}.yaml"
  }
}

resource "proxmox_virtual_environment_file" "vm_image" {
  content_type = "iso"
  datastore_id = var.pve_datastore_data
  node_name    = var.pve_node_name

  source_file {
    path = var.vm_image_url

    # Ensures that the file actually gets uploaded
    file_name = replace(basename(var.vm_image_url), "qcow2", "img")
  }
}

resource "proxmox_virtual_environment_vm" "load_balancer" {
  name        = local.vm_name
  description = "Managed by Terraform"
  node_name   = var.pve_node_name
  vm_id       = var.vm_id

  tags = [
    "debian",
    "load-balancer",
    "terraform"
  ]

  keyboard_layout = "de-ch"

  agent {
    enabled = false
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
    
    ip_config {
      ipv4 {
        address = "${var.vm_ip_address}/${local.vm_ipv4_cidr}"
        gateway = "${local.vm_network_address}.${local.vm_gateway_last_octet}"
      }
    }

    /*
    user_account {
      keys     = [trimspace(var.vm_ssh_key)]
      password = random_password.vm_password.result
      username = "ansible"
    }*/
  }

  cpu {
    cores   = var.vm_cpu_cores
    sockets = var.vm_cpu_sockets
  }

  memory {
    dedicated = var.vm_memory
  }

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  disk {
    datastore_id = var.pve_datastore_vm
    file_id      = proxmox_virtual_environment_file.vm_image.id
    interface    = "scsi0"

    size = var.vm_disk_size
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    #https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#operating_system
    type = "l26"
  }

  lifecycle {
    ignore_changes = [
      description
      # Will always trigger changes
    ]
  }
}
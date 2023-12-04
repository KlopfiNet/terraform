/*
data "vault_generic_secret" "pm_terraform_host_ssh_pub" {
  path = "secret/proxmox/server_pub_key"
}
*/

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

resource "random_password" "password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "proxmox_virtual_environment_file" "os_image" {
  content_type = "iso"
  datastore_id = var.pve_datastore_data
  node_name    = var.pve_node_name

  source_file {
    path      = var.vm_image_url
    file_name = replace(basename(var.vm_image_url), "qcow2", "img")
  }
}

resource "proxmox_virtual_environment_file" "provision_file" {
  for_each = { for n in var.nodes : n.name => n }

  content_type = "snippets"
  datastore_id = var.pve_datastore_data
  node_name    = var.pve_node_name

  source_raw {
    data = templatefile("${path.module}/templates/cloud_config.tmpl", {
      ssh_key  = var.node_ssh_key
      hostname = each.value.name
      password = random_password.password.result
    })

    file_name = "cloud_config-${each.value.vm_id}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each = { for n in var.nodes : n.name => n }

  name        = each.value.name
  description = "Managed by Terraform"
  node_name   = var.pve_node_name
  vm_id       = each.value.vm_id

  tags = [
    "debian",
    "kubernetes",
    each.value.master ? "master" : "worker",
    "terraform"
  ]

  keyboard_layout = "de-ch"

  agent {
    enabled = false
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.provision_file[each.value.name].id

    ip_config {
      # Somehow cannot be set in cloud-init file
      ipv4 {
        address = "${local.ip_network}.${each.value.ip_octet}/24"
        gateway = "${local.ip_network}.1"
      }
    }

    dns {
      server = "${local.ip_network}.20"
      domain = "klopfi.net"
    }
  }

  cpu {
    cores   = var.node_cpu_cores
    sockets = var.node_cpu_sockets
  }

  memory {
    dedicated = var.node_memory
  }

  startup {
    order      = "3"
    up_delay   = "0"
    down_delay = "10"
  }

  disk {
    datastore_id = var.pve_datastore_vm
    file_id      = proxmox_virtual_environment_file.os_image.id
    interface    = "scsi0"

    size = "20"
    # Provider default of 8GB wants to shrink the image, resulting in an error:
    #  qemu-img: Use the --shrink option to perform a shrink operation.
    #  qemu-img: warning: Shrinking an image will delete all data beyond the shrunken image's end. Before performing such an operation, make sure there is no important data there.
  }

  timeout_create = "2400"

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    #https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#operating_system
    type = "l26"
  }
}
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
    dns = {
      source  = "hashicorp/dns"
      version = "3.3.2"
    }
  }
}

locals {
  # 10.0.1.<ip_ident><node_index>
  ip_ident = {
    master = 9
    worker = 10
    infra  = 11
  }

  # <vmid_ident><node_index>; 10.0.1.81 (master, first node)
  vmid_ident = {
    master = 8
    worker = 9
    infra  = 1
  }

  node_instances = flatten([
    for node_key, node_value in var.nodes : [
      for i in range(node_value.count) : {
        role      = node_key
        instance  = i + 1
        name      = "kubernetes-${node_key}-${i + 1}"
        vmid      = "9${local.vmid_ident[node_key]}${i + 1}"
        ip        = "${local.ip_network}.${local.ip_ident[node_key]}${i + 1}"
        ip_octet  = "${local.ip_ident[node_key]}${i + 1}"
        resources = node_value.resources
      }
    ]
  ])
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
  for_each = { for idx, instance in local.node_instances : "${instance.role}-${instance.instance}" => instance }

  content_type = "snippets"
  datastore_id = var.pve_datastore_data
  node_name    = var.pve_node_name

  source_raw {
    data = templatefile("${path.module}/templates/cloud_config.tmpl", {
      ssh_key  = var.node_ssh_key
      hostname = each.value.name
      password = random_password.password.result
    })

    file_name = "cloud_config-${each.value.vmid}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each = { for idx, instance in local.node_instances : "${instance.role}-${instance.instance}" => instance }

  name        = each.value.name
  description = "Managed by Terraform"
  node_name   = var.pve_node_name
  vm_id       = each.value.vmid

  /*
"https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
replace(basename(var.vm_image_url), "qcow2", "img")
*/

  tags = sort([
    # Automatically determine OS using image name: ">debian<-version-type.iso"
    split(".", split("-", basename(var.vm_image_url))[0])[0],
    each.value.role,
    "terraform",
    "kubernetes"
  ])

  keyboard_layout = "de-ch"

  agent {
    enabled = true
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.provision_file["${each.key}"].id

    ip_config {
      # Somehow cannot be set in cloud-init file
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "${local.ip_network}.1"
      }
    }

    dns {
      server = "${local.ip_network}.20"
      domain = "klopfi.net"
    }
  }

  cpu {
    cores   = each.value.resources.cores
    sockets = each.value.resources.sockets
  }

  memory {
    dedicated = each.value.resources.memory
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
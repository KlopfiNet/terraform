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
    ignition = {
      source  = "community-terraform-providers/ignition"
      version = "2.2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

resource "proxmox_virtual_environment_file" "flatcar_image" {
  content_type = "iso"
  datastore_id = var.pve_datastore_data
  node_name    = var.pve_node_name

  source_file {
    path = "https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img"
  }
}

resource "proxmox_virtual_environment_file" "ignition" {
  for_each = {
    for n in var.nodes : n.name => n
  }

  depends_on = [data.ignition_config.base]

  content_type = "snippets"
  datastore_id = var.pve_datastore_data
  node_name    = var.pve_node_name

  source_raw {
    data      = data.ignition_config.base[each.value.name].rendered
    file_name = "machine-transpiled-${each.value.vm_id}.ign"
  }
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each = {
    for n in var.nodes : n.name => n
  }

  name        = each.value.name
  description = "Managed by Terraform"
  node_name   = var.pve_node_name
  vm_id       = each.value.vm_id

  tags = [
    "terraform",
    "flatcar",
    "kubernetes"
  ]

  keyboard_layout = "de-ch"

  # Very annoyingly, this can only be executed with *the* root account as of PX 8.1.3
  kvm_arguments = "-fw_cfg name=opt/com.coreos/config,file=${var.pve_snippets_pwd}/${proxmox_virtual_environment_file.ignition[each.value.name].file_name}"

  # Flatcar has the qemu-guest-package installed already
  agent {
    enabled = true
  }

  cpu {
    cores   = var.node_cpu_cores
    sockets = var.node_cpu_sockets
  }

  memory {
    // Flatcar requires at least 3GB
    dedicated = var.node_memory
  }

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  disk {
    datastore_id = var.pve_datastore_vm
    file_id      = proxmox_virtual_environment_file.flatcar_image.id
    interface    = "scsi0"

    size = "20"
    # Provider default of 8GB wants to shrink the image, resulting in an error:
    #  qemu-img: Use the --shrink option to perform a shrink operation.
    #  qemu-img: warning: Shrinking an image will delete all data beyond the shrunken image's end. Before performing such an operation, make sure there is no important data there.
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    #https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#operating_system
    type = "l26"
  }
}
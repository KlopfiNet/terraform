locals {
  vm_resources = {
    "controlplane" = {
      sockets = var.node_controlplane_cpu_sockets,
      cpu     = var.node_controlplane_cpu_cores,
      memory  = var.node_controlplane_memory
    },
    "worker" = {
      sockets = var.node_worker_cpu_sockets,
      cpu     = var.node_worker_cpu_cores,
      memory  = var.node_worker_memory
    },
    "infra" = {
      sockets = var.node_infra_cpu_sockets,
      cpu     = var.node_infra_cpu_cores,
      memory  = var.node_infra_memory
    }
  }
}

resource "proxmox_virtual_environment_download_file" "os_image" {
  content_type = "iso"
  datastore_id = var.pve_datastore_data
  node_name    = var.pve_node_name
  file_name    = "talos-${var.talos_version}.iso"
  overwrite    = true
  url          = data.talos_image_factory_urls.this.urls.iso
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each = { for vm in local.vm_instances : vm.name => vm }

  name        = each.value.name
  description = "Managed by Terraform"
  node_name   = var.pve_node_name

  vm_id = each.value.vmid

  tags = sort([
    each.value.role,
    "talos",
    "terraform",
    "kubernetes"
  ])

  keyboard_layout = "de-ch"

  agent {
    enabled = false
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${local.ip_network}.${each.value.ip_octet}/24"
        gateway = "${local.ip_network}.1"
      }
    }
  }

  cpu {
    cores   = local.vm_resources[each.value.role].cpu
    type    = "x86-64-v2-AES"
    sockets = local.vm_resources[each.value.role].sockets
  }

  memory {
    dedicated = local.vm_resources[each.value.role].memory
  }

  startup {
    order      = each.value.role == "controlplane" ? "1" : "2"
    up_delay   = each.value.role == "controlplane" ? "0" : "30"
    down_delay = "10"
  }

  disk {
    datastore_id = var.pve_datastore_vm
    file_id      = proxmox_virtual_environment_download_file.os_image.id
    file_format  = "raw"
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
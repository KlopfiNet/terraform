terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=2.9.14"
    }
  }
}

data "vault_generic_secret" "pm_terraform_host_ssh_pub" {
  path = "secret/proxmox/server_pub_key"
}

resource "proxmox_vm_qemu" "resource-name" {
  for_each = { 
    for n in var.rancher_master_nodes : n.name => n
  }

  name        = each.value.name
  target_node = "hv"
  
  clone = "rke2-template.klopfi.net"

  storage = "vms" # "vms" storage location
  cores   = 2
  sockets = 1
  memory  = 4096
  disk_gb = 20
  nic     = "virtio"
  bridge  = "vmbr0"

  ssh_user = "root"
  #ssh_private_key = vault_generic_secret.pm_provisioned_server_ssh_pem["value"]

  os_type   = "cloud-init"
  ipconfig0 = format("ip=10.0.1.%s/16,gw=10.0.1.1", each.value.ip)

  sshkeys = data.vault_generic_secret.pm_terraform_host_ssh_pub.data["value"]

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]
  }
}
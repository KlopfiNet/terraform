output "ansible_password" {
  value     = random_password.password.result
  sensitive = true
}

output "node_mac_addresses" {
  value = values(proxmox_virtual_environment_vm.node)[*].mac_addresses
}

output "inventory" {
  value = templatefile("${path.module}/templates/inventory.tmpl", {
    hosts      = var.nodes
    ip_network = local.ip_network
  })
}
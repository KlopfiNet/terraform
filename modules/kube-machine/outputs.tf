output "butane_ansible_password" {
  value     = random_password.password.result
  sensitive = true
}

output "node_ipv4_addresses" {
  value = values(proxmox_virtual_environment_vm.node)[*].ipv4_addresses
}

output "node_mac_addresses" {
  value = values(proxmox_virtual_environment_vm.node)[*].mac_addresses
}
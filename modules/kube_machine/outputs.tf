output "ansible_password" {
  value     = random_password.password.result
  sensitive = true
}

output "inventory" {
  value = templatefile("${path.module}/templates/inventory.tmpl", {
    hosts      = local.node_instances
    ip_network = local.ip_network
  })
}

output "ssh_config" {
  value = templatefile("${path.module}/templates/ssh_config.tmpl", {
    hosts = local.node_instances
  })
}
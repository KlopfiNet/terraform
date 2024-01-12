output "vm_password" {
  value = random_password.vm_password.result
}

output "inventory" {
  value = templatefile("${path.module}/templates/inventory.tmpl", {
    ip = var.vm_ip_address
  })
}
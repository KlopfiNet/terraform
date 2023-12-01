# Create ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tmpl", {
    ip = var.lxc_ip_address
  })
  filename = "./outputs/inventory_lb"
}
# Create ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tmpl", {
    hosts      = var.nodes
    ip_network = local.ip_network
  })
  filename = "./outputs/inventory_kubernetes.ini"
}
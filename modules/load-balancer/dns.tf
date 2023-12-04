provider "dns" {
  update {
    server = "${local.ip_network}.20"
  }
}

resource "dns_a_record_set" "load_balancer" {
  zone = "${local.dns_zone}."
  name = "kubernetes"
  addresses = [
    var.vm_ip_address,
  ]
  ttl = 3600
}
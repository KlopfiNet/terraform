provider "dns" {
  update {
    server = "${local.ip_network}.20"
  }
}

resource "dns_a_record_set" "kube_machine" {
  for_each = { for n in var.nodes : n.name => n }

  zone = "${local.dns_zone}."
  name = each.value.name
  addresses = [
    "${local.ip_network}.${each.value.ip_octet}",
  ]
  ttl = 300
}
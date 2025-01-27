provider "dns" {
  update {
    server = "${local.ip_network}.20"
  }
}

locals {
  reverse_zone_ip = join(".", reverse(split(".", local.ip_network)))
  infra_node_ips  = [for vm in local.vm_instances : "${local.ip_network}.${vm.ip_octet}" if vm.role == "infra"]
}

resource "dns_a_record_set" "kube_vip" {
  zone = "${local.dns_zone}."
  name = "kubernetes"
  addresses = [
    local.cluster_vip
  ]
  ttl = 3600
}

resource "dns_a_record_set" "kube_machine" {
  for_each = { for vm in local.vm_instances : vm.name => vm }

  zone = "${local.dns_zone}."
  name = each.value.name
  addresses = [
    "${local.ip_network}.${each.value.ip_octet}",
  ]
  ttl = 300
}

resource "dns_ptr_record" "kube_machine" {
  for_each = { for vm in local.vm_instances : vm.name => vm }

  zone = "${local.reverse_zone_ip}.in-addr.arpa."
  name = each.value.ip_octet
  ptr  = "${each.value.name}.${local.dns_zone}."
  ttl  = 300
}

resource "dns_a_record_set" "apps_ingress_internal" {
  zone      = "${local.dns_zone}."
  name      = "*.apps"
  addresses = local.infra_node_ips
  ttl       = 300
}
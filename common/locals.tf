locals {
  # Only populate first 3 octets, leaving no trailing dot
  ip_network      = "10.0.1"
  ip_network_cidr = 24
  dns_zone        = "klopfi.net"
}

# ---------
locals {
  vmid_base = 900

  cluster_prefix   = "klopfinet"
  cluster_endpoint = "https://kubernetes.klopfi.net:6443"

  cluster_name = "${local.cluster_prefix}-cluster"
  cluster_vip  = "${local.ip_network}.80"

  # Flatten var.nodes so it may be used in for_each
  vm_instances = flatten([
    for n in var.nodes : [
      for i in range(n.count) : {
        role  = n.role
        index = i + 1
        name  = "talos-${n.role}-${i + 1}"

        # Extend base vm_id by vmid_base + (n * 10): Master = 0, Worker = 10, Infra = 20
        vmid     = local.vmid_base + ((n.role == "master" ? 0 : (n.role == "worker" ? 1 : 2)) * 10) + i + 1
        ip_octet = n.role == "master" ? 30 : (n.role == "worker" ? 40 : 60) + i + 1
      }
    ]
  ])
}
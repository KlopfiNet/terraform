resource "talos_machine_secrets" "common" {
  talos_version = var.talos_version
}

locals {
  config_network_common = {
    machine = {
      network = {
        nameservers   = ["10.0.1.20"]
        searchDomains = ["klopfi.net"]
      }
    }
    cluster = {
      network = {
        cni = {
          name = "none" # Is Cilium but installed via Helm
        }
      }
      proxy = {
        disabled = true
      }
    }
  }

  first_master_ip_octet = lookup(
    flatten([
      for vm in local.vm_instances :
      (vm.role == "master" ? [vm] : [])
    ])[0],
    "ip_octet",
    null
  )
}

data "talos_machine_configuration" "controlplane" {
  kubernetes_version = var.kubernetes_version
  talos_version      = var.talos_version

  cluster_name     = local.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.common.machine_secrets
  machine_type     = "controlplane"

  config_patches = [
    yamlencode(local.config_network_common),
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = "eth0"
              vip = {
                ip = local.cluster_vip
              }
            }
          ]
        }
      }
      cluster = {
        inlineManifests = [
          {
            name     = "cilium"
            contents = join("---\n", [data.helm_template.cilium.manifest])
          }
        ]
      }
    })
  ]
}

data "talos_machine_configuration" "worker" {
  kubernetes_version = var.kubernetes_version
  talos_version      = var.talos_version

  cluster_name     = local.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.common.machine_secrets
  machine_type     = "worker"

  config_patches = [
    yamlencode(local.config_network_common)
  ]
}

# ----------------------
data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.common.client_configuration
  endpoints            = [for vm in local.vm_instances : "${local.ip_network}.${vm.ip_octet}"]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = { for vm in local.vm_instances : vm.name => vm }

  client_configuration        = talos_machine_secrets.common.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = "${local.ip_network}.${each.value.ip_octet}"
  endpoint                    = "${local.ip_network}.${each.value.ip_octet}"
  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = each.value.name
        }
      }
    })
  ]

  depends_on = [
    proxmox_virtual_environment_vm.node
  ]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.common.client_configuration
  node                 = "${local.ip_network}.${local.first_master_ip_octet}"
  endpoint             = "${local.ip_network}.${local.first_master_ip_octet}"

  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.common.client_configuration
  node                 = "${local.ip_network}.${local.first_master_ip_octet}"
  endpoint             = "${local.ip_network}.${local.first_master_ip_octet}"
  depends_on = [
    talos_machine_bootstrap.this,
  ]
}
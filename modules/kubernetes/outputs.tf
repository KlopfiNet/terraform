output "talos_machine_config" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "talos_kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talos_image_data" {
  value = {
    data                                    = talos_image_factory_schematic.this.id
    talos_image_factory_schematic           = talos_image_factory_schematic.this
    talos_image_factory_extensions_versions = data.talos_image_factory_extensions_versions.this
  }
}

output "talos_nodes" {
  value = [for vm in local.vm_instances : "${local.ip_network}.${vm.ip_octet}"]
}
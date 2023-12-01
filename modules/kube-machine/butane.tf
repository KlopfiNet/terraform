/*
  REFERENCE
  https://registry.terraform.io/providers/community-terraform-providers/ignition/latest/docs
*/

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

data "ignition_user" "ansible" {
  name     = "ansible"
  home_dir = "/home/ansible/"
  shell    = "/bin/bash"
  system   = true
  groups   = ["sudo"]

  password_hash = random_password.password.bcrypt_hash

  ssh_authorized_keys = [var.node_ssh_key]
}

# Single things
data "ignition_link" "kubernetes-sysext" {
  target = "/opt/extensions/kubernetes/kubernetes-${var.kubernetes_version}-x86-64.raw"
  path   = "/etc/extensions/kubernetes.raw"
  hard   = false
}

data "ignition_file" "kubernetes-conf" {
  overwrite = true
  path      = "/etc/sysupdate.kubernetes.d/kubernetes.conf"
  source {
    source = "https://github.com/flatcar/sysext-bakery/releases/download/latest/kubernetes.conf"
  }

}

data "ignition_file" "noop-conf" {
  overwrite = true
  path      = "/etc/sysupdate.d/noop.conf"
  source {
    source = "https://github.com/flatcar/sysext-bakery/releases/download/latest/noop.conf"
  }
}

data "ignition_file" "kubernetes-sysext" {
  overwrite = true
  path      = "/opt/extensions/kubernetes/kubernetes-${var.kubernetes_version}-x86-64.raw"
  source {
    source = "https://github.com/flatcar/sysext-bakery/releases/download/latest/kubernetes-${var.kubernetes_version}-x86-64.raw"
  }
}

data "ignition_systemd_unit" "sysupdate-timer" {
  name    = "systemd-sysupdate.timer"
  enabled = true
}

data "ignition_systemd_unit" "sysupdate-service" {
  name = "systemd-sysupdate.service"
  dropin {
    name    = "kubernetes.conf"
    content = <<-EOT
      [Service]
      ExecStartPre=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/kubernetes.raw > /tmp/kubernetes"
      ExecStartPre=/usr/lib/systemd/systemd-sysupdate -C kubernetes update
      ExecStartPost=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/kubernetes.raw > /tmp/kubernetes-new"
      ExecStartPost=/usr/bin/sh -c "[[ \$(cat /tmp/kubernetes) != \$(cat /tmp/kubernetes-new) ]] && touch /run/reboot-required"
    EOT
  }
}

# -----------------------------------------

data "ignition_file" "hostname" {
  for_each = {
    for n in var.nodes : n.name => n
  }

  overwrite = true
  path      = "/etc/hostname"
  mode      = 420 # Octal 0644
  content {
    content = each.value.name
  }
}

data "ignition_file" "network" {
  for_each = {
    for n in var.nodes : n.name => n
  }

  overwrite = true
  path      = "/etc/systemd/network/00-eth0.network"
  mode      = 420 # Octal 0644
  content {
    content = <<-EOT
    [Match]
    Name=eth0

    [Network]
    DNS=${local.ip_network}.1
    Address=${local.ip_network}.${each.value.ip_octet}/24
    Gateway=${local.ip_network}.1
    EOT
  }
}

# Rendered config
data "ignition_config" "base" {
  for_each = {
    for n in var.nodes : n.name => n
  }

  users = [data.ignition_user.ansible.rendered]
  files = [
    data.ignition_file.hostname[each.value.name].rendered,
    data.ignition_file.network[each.value.name].rendered,

    # Common files
    /*
    data.ignition_file.kubernetes-conf.rendered,
    data.ignition_file.kubernetes-sysext.rendered,
    data.ignition_file.noop-conf.rendered
    */
  ]

  links = [data.ignition_link.kubernetes-sysext.rendered]

  /*
  systemd = [
    data.ignition_systemd_unit.sysupdate-timer.rendered,
    data.ignition_systemd_unit.sysupdate-service.rendered,

    # Only execute on initial node!
    #data.ignition_systemd_unit.kubeadm-service-initial.rendered
  ]
  */
}
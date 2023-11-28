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

  ssh_authorized_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCu4fiOTww/TdSaksYnkAGvslv27TOciqoDhzCV3AD9/h/7iy3UVHiocia5i04Uy/nlLsDZOPh6/OqB+6SjDMkOk4/7exttQTW82Ae2WrruGXowWf++7ZhIGtJVlANbikDzyqKbNUpOUoMG3+X0g2KAQ4o0+RWTiCwpZ2noediCHevegXmP8azO8BiM50zPOBxYPfKeErepYvtQyPd/gT/Z9wZHVUlHaXDWcXJYBp9F8Da79hl7qSqWkNZjOLTRGrCD8deZddqRJar23H8/5JiuWSqsWh83W1YGGlTuTLwVGlin8NEHkzc3t31MF2ExbJZIV04DSuCU4JGDDCMaWqjrjGUJOFRNWzC6+53YmQdg3dllqCSHZV8fULA2DTS7ssqO4SH03INnBY/d3hamBUkEmN0PkRUt6hPJ6OSlocTAFYY8gq2VIt902mpQMN45OJ+8LZz6Joca9eK/QQuEWUXnaTME3gydHCDE4BpU5D7C0cvaI1UBYQ/0RhTZM0tvt38= pi@raspberrypi"
  ]
}

# Single things
data "ignition_link" "kubernetes-sysext" {
  target = "/opt/extensions/kubernetes/kubernetes-${var.kubernetes_version}-x86-64.raw"
  path   = "/etc/extensions/kubernetes.raw"
  hard   = true
}

data "ignition_file" "kubernetes-conf" {
  path = "/etc/sysupdate.kubernetes.d/kubernetes.conf"
  source {
    source = "https://github.com/flatcar/sysext-bakery/releases/download/latest/kubernetes.conf"
  }
}

data "ignition_file" "noop-conf" {
  path = "/etc/sysupdate.d/noop.conf"
  source {
    source = "https://github.com/flatcar/sysext-bakery/releases/download/latest/noop.conf"
  }
}

data "ignition_file" "kubernetes-sysext" {
  path = "/opt/extensions/kubernetes/kubernetes-${var.kubernetes_version}-x86-64.raw"
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
    ExecStartPre=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/kubernetes.raw > /tmp/kubernetes"
    ExecStartPre=/usr/lib/systemd/systemd-sysupdate -C kubernetes update
    ExecStartPost=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/kubernetes.raw > /tmp/kubernetes-new"
    ExecStartPost=/usr/bin/sh -c "[[ $(cat /tmp/kubernetes) != $(cat /tmp/kubernetes-new) ]] && touch /run/reboot-required"
    EOT
    # error at $.contents: invalid unit content: found garbage after section name : "] && touch /run/reboot-required\""
  }
}

# The following service may only run on one control plane node
data "ignition_systemd_unit" "kubeadm-service-initial" {
  name    = "kubeadm.service"
  enabled = true
  content = <<-EOT
  [Unit]
  Description=Kubeadm service
  Requires=containerd.service
  After=containerd.service
  ConditionPathExists=!/etc/kubernetes/kubelet.conf
  [Service]
  ExecStartPre=/usr/bin/kubeadm init
  ExecStartPre=/usr/bin/mkdir /home/core/.kube
  ExecStartPre=/usr/bin/cp /etc/kubernetes/admin.conf /home/core/.kube/config
  ExecStart=/usr/bin/chown -R core:core /home/core/.kube
  [Install]
  WantedBy=multi-user.target
  EOT
}

# -----------------------------------------

data "ignition_file" "hostname" {
  for_each = {
    for n in var.nodes : n.name => n
  }

  path = "/etc/hostname"
  mode = 420 # Octal 0644
  content {
    content = each.value.name
  }
}

data "ignition_file" "network" {
  for_each = {
    for n in var.nodes : n.name => n
  }

  path = "/etc/systemd/network/00-eth0.network"
  mode = 420 # Octal 0644
  content {
    content = <<-EOT
    [Match]
    Name=eth0

    [Network]
    DNS=10.0.1.1
    Address=10.0.1.${each.value.ip_octet}/24
    Gateway=10.0.1.1
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
    data.ignition_file.kubernetes-conf.rendered,
    data.ignition_file.kubernetes-sysext.rendered,
    data.ignition_file.noop-conf.rendered
  ]

  links = [data.ignition_link.kubernetes-sysext.rendered]
  systemd = [
    data.ignition_systemd_unit.sysupdate-timer.rendered,
    data.ignition_systemd_unit.sysupdate-service.rendered,

    # Only execute on initial node!
    data.ignition_systemd_unit.kubeadm-service-initial.rendered
  ]
}
/*
  REFERENCE
  https://registry.terraform.io/providers/community-terraform-providers/ignition/latest/docs
*/

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

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

data "ignition_user" "ansible" {
  name     = "ansible"
  home_dir = "/home/ansible/"
  shell    = "/bin/bash"
  system   = true
  groups   = [ "sudo" ]

  password_hash = random_password.password.bcrypt_hash

  ssh_authorized_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCu4fiOTww/TdSaksYnkAGvslv27TOciqoDhzCV3AD9/h/7iy3UVHiocia5i04Uy/nlLsDZOPh6/OqB+6SjDMkOk4/7exttQTW82Ae2WrruGXowWf++7ZhIGtJVlANbikDzyqKbNUpOUoMG3+X0g2KAQ4o0+RWTiCwpZ2noediCHevegXmP8azO8BiM50zPOBxYPfKeErepYvtQyPd/gT/Z9wZHVUlHaXDWcXJYBp9F8Da79hl7qSqWkNZjOLTRGrCD8deZddqRJar23H8/5JiuWSqsWh83W1YGGlTuTLwVGlin8NEHkzc3t31MF2ExbJZIV04DSuCU4JGDDCMaWqjrjGUJOFRNWzC6+53YmQdg3dllqCSHZV8fULA2DTS7ssqO4SH03INnBY/d3hamBUkEmN0PkRUt6hPJ6OSlocTAFYY8gq2VIt902mpQMN45OJ+8LZz6Joca9eK/QQuEWUXnaTME3gydHCDE4BpU5D7C0cvaI1UBYQ/0RhTZM0tvt38= pi@raspberrypi"
  ]

}

# Rendered config
data "ignition_config" "base" {
  for_each = {
    for n in var.nodes : n.name => n
  }

  users = [data.ignition_user.ansible.rendered]
  files = [
    data.ignition_file.hostname[each.value.name].rendered,
    data.ignition_file.network[each.value.name].rendered
  ]
}
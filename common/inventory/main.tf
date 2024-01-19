terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.51.1"
    }
  }
}

variable cluster_prefix {}
variable ssh_user {}

# variable master_as_edge {}

variable master_hostnames {
  type = list(string)
}

variable master_public_ip {
  # type = list(string)
}

variable master_private_ip {
  type = list(string)
}

variable worker_count {}

variable worker_hostnames {
  type = list(string)
}

variable worker_public_ip {
  type = list(string)
}

variable worker_private_ip {
  type = list(string)
}

# Generate Ansible inventory (identical for each cloud provider)
resource "null_resource" "generate-inventory" {
  # Trigger rewrite of inventory, uuid() generates a random string everytime it is called
  triggers = {
    uuid = "${uuid()}"
  }

  # Write master
  provisioner "local-exec" {
    command = "echo \"[masters]\" > inventory"
  }

  # output the lists formated
  provisioner "local-exec" {
    command = "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=${var.ssh_user}", var.master_hostnames, var.master_public_ip))}\" >> inventory"
  }

  # Write edges
  # provisioner "local-exec" {
  #   command = "echo \"[edge]\" >> inventory"
  # }

  # only output if master is edge
  # provisioner "local-exec" {
  #   command = "echo \"${var.master_as_edge != true ? "" : join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=${var.ssh_user}", var.master_hostnames, var.master_public_ip))}\" >> inventory"
  # }

  # output the lists formated, slice list to make sure hostname and ip-list have same length
  # provisioner output can not be empty string - therefore output space when edge_count == 0
  # provisioner "local-exec" {
  #   command = "echo \"${var.edge_count == 0 ? " " : join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=${var.ssh_user}", slice(var.edge_hostnames,0,var.edge_count), var.edge_public_ip))}\" >> inventory"
  # }

  # Write other variables
  provisioner "local-exec" {
    command = "echo \"[all:vars]\" >> inventory"
  }

  provisioner "local-exec" {
    command = "echo \"workers_count=${var.worker_count} \" >> inventory"
  }

  # If cloudflare domain is set, output that domain, otherwise output a nip.io domain (with the first edge ip)
  # provisioner "local-exec" {
  #   command = "echo \"domain=${ var.domain }\" >> inventory"
  # }

  # Write master
  provisioner "local-exec" {
    command = "echo \"[workers]\" >> inventory"
  }
  # output the lists formated of workers
  provisioner "local-exec" {
    command = "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=${var.ssh_user}", var.worker_hostnames, var.worker_private_ip))}\" >> inventory"
  }
}

output "master_hostnames" {
  value = var.master_hostnames
}
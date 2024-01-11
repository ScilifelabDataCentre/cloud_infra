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

variable boot_image {}

variable ssh_key {
  default = "ssh_key.pub"
}

variable network_name {
  default = ""
}

variable external_network_uuid {}

variable dns_nameservers {
  default = "8.8.8.8,8.8.4.4"
  type = string
}

variable secgroup_name {
  default = ""
}

variable floating_ip_pool {}
variable kubeadm_token {}

# Master settings
variable master_count {
  default = 1
}

variable master_flavor {}

variable master_flavor_id {
  default = ""
}

variable ssh_user {
  default = "ubuntu"
}

variable master_as_edge {
  default = "false"
}

provider "openstack" {}

# Create master nodes
# resource "openstack_compute_instance_v2" "cks-master" {
#   count           = 1
#   name            = "cks-master"
#   image_id        = "3112317c-4589-4bf4-bceb-8b090c6a0d19"
#   flavor_name     = "ssc.small"
#   key_pair = "${module.keypair.keypair_name}"
#   security_groups = ["${module.secgroup.secgroup_name}"]

#   metadata = {
#     this = "that"
#   }

#   network {
#     name = "NAISS 2023/7-7 Internal IPv4 Network"
#   }
# }

# Create worker nodes
resource "openstack_compute_instance_v2" "cks-worker" {
  count           = 1
  name            = "cks-worker"
  image_id        = "3112317c-4589-4bf4-bceb-8b090c6a0d19"
  flavor_name     = "ssc.small"
  key_pair = "${module.keypair.keypair_name}"
  security_groups = ["${module.secgroup.secgroup_name}"]

  metadata = {
    this = "that"
  }

  network {
    name       = "${module.network.network_name}"
    # name = "NAISS 2023/7-7 Internal IPv4 Network"
  }
}

# Upload SSH key to OpenStack
module "keypair" {
  source      = "./keypair"
  public_key  = "${var.ssh_key}"
  name_prefix = "${var.cluster_prefix}"
}

# Network
module "network" {
  source            = "./network"
  network_name      = "${var.network_name}"
  external_net_uuid = "${var.external_network_uuid}"
  name_prefix       = "${var.cluster_prefix}"
  dns_nameservers   = "${var.dns_nameservers}"
}

# Secgroup
module "secgroup" {
  source        = "./secgroup"
  secgroup_name = "${var.secgroup_name}"
  name_prefix   = "${var.cluster_prefix}"
}

module "master" {
  # Core settings
  source      = "./node"
  m_count     = "${var.master_count}"
  name_prefix = "${var.cluster_prefix}-master"
  flavor_name = "${var.master_flavor}"
  flavor_id   = "${var.master_flavor_id}"
  image_name  = "${var.boot_image}"

  # SSH settings
  ssh_user     = "${var.ssh_user}"
  keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  network_name       = "${module.network.network_name}"
  # network_name = "NAISS 2023/7-7 Internal IPv4 Network"

  secgroup_name      = "${module.secgroup.secgroup_name}"
  assign_floating_ip = "true"
  floating_ip_pool   = "${var.floating_ip_pool}"

  # Disk settings
  extra_disk_size = "0"

  # Bootstrap settings
  # bootstrap_file = "bootstrap/master.sh"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = "${split(",", var.master_as_edge == "true" ? "role=edge" : "")}"
  node_taints    = [""]
  master_ip      = ""
}
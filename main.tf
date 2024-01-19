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

variable worker_count {
  default = 1 
}

variable worker_flavor {}

variable worker_flavor_id {
  default = ""
}
  
variable ssh_user {
  default = "ubuntu"
}

variable master_as_edge {
  default = "false"
}

provider "openstack" {}

# Upload SSH key to OpenStack
module "keypair" {
  source      = "./keypair"
  public_key  = "${var.ssh_key}"
  name_prefix = "${var.cluster_prefix}"
}

# Network
module  "network" {
  source            = "./network"
  count             = "${var.network_name == "" ? 1 : 0}"
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
  # network_name = "NAISS 2023/7-7 Internal IPv4 Network"
  # network_name = "test-net"
  network_name       = "${length(module.network) > 0 ? module.network[0].network_name : var.network_name}"
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

module "worker" {
  # Core settings
  source      = "./node"
  m_count       = "${var.worker_count}"
  name_prefix = "${var.cluster_prefix}-worker"
  flavor_name = "${var.worker_flavor}"
  flavor_id   = "${var.worker_flavor_id}"
  image_name  = "${var.boot_image}"

  # SSH settings
  ssh_user     = "${var.ssh_user}"
  keypair_name = "${module.keypair.keypair_name}"

  # Network settings
  network_name       = "${length(module.network) > 0 ? module.network[0].network_name : var.network_name}"
  secgroup_name      = "${module.secgroup.secgroup_name}"
  assign_floating_ip = "false"
  floating_ip_pool   = ""

  # Disk settings
  extra_disk_size = "0"

  # Bootstrap settings
  # bootstrap_file = "bootstrap/worker.sh"
  kubeadm_token  = "${var.kubeadm_token}"
  node_labels    = ["role=node"]
  node_taints    = [""]
  master_ip      = "${element(module.master.local_ip_v4, 0)}"
}

# Generate Ansible inventory (identical for each cloud provider)
module "generate-inventory" {
  source             = "./common/inventory"
  cluster_prefix     = "${var.cluster_prefix}"
  ssh_user           = "${var.ssh_user}"
  master_hostnames   = module.master.hostnames        # No need to access the first element
  master_public_ip   = module.master.public_ip        # No need to access the first element
  master_private_ip  = module.master.local_ip_v4      # No need to access the first element
  worker_count       = var.worker_count
  worker_hostnames   = module.worker.hostnames        # No need to access the first element
  worker_public_ip   = module.worker.public_ip        # No need to access the first element
  worker_private_ip  = module.worker.local_ip_v4      # No need to access the first element
}

output "test" {
  value = module.generate-inventory.master_hostnames
}
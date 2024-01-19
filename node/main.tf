terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.51.1"
    }
  }
}


# Core settings
variable m_count {}

variable name_prefix {}
variable flavor_name {}
variable flavor_id {}
variable image_name {}

# SSH settings
variable ssh_user {}

variable keypair_name {}

# Network settings
variable network_name {}

variable secgroup_name {}

variable assign_floating_ip {
  default = false
}

variable floating_ip_pool {}

# Disk settings
variable extra_disk_size {
  default = 0
}

# Bootstrap settings
# variable bootstrap_file {}

variable kubeadm_token {}

variable node_labels {
  type = list(string)
}

variable node_taints {
  type = list(string)
}

variable master_ip {
  default = ""
}

# Bootstrap
# data "template_file" "instance_bootstrap" {
#   template = file("${path.root}/${var.bootstrap_file}")

  # template_vars {
  #   kubeadm_token = "${var.kubeadm_token}"
  #   master_ip     = "${var.master_ip}"
  #   node_labels   = "${join(",", var.node_labels)}"
  #   node_taints   = "${join(",", var.node_taints)}"
  #   ssh_user      = "${var.ssh_user}"
  # }

# data "template_file" "cloud_init_template" {
#   template = file("${path.root}/${var.bootstrap_file}")
# }


# Create instances
resource "openstack_compute_instance_v2" "instance" {
  count       = "${var.m_count}"
  name        = "${var.name_prefix}-${format("%03d", count.index)}"
  image_name  = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  flavor_id   = "${var.flavor_id}"
  key_pair    = "${var.keypair_name}"

  network {
    name = "${var.network_name}"
  }

  security_groups = ["${var.secgroup_name}"]
  # user_data       = "${data.template_file.cloud_init_template.rendered}"
}

# Allocate floating IPs (optional)
resource "openstack_compute_floatingip_v2" "floating_ip" {
  count = "${var.assign_floating_ip ? var.m_count : 0}"
  pool  = "${var.floating_ip_pool}"
}

# Associate floating IPs (if created)
resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
  count       = "${var.assign_floating_ip ? var.m_count : 0}"
  floating_ip = "${element(openstack_compute_floatingip_v2.floating_ip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.instance.*.id, count.index)}"
}

# Create extra disk (optional)
resource "openstack_blockstorage_volume_v2" "extra_disk" {
  count = "${var.extra_disk_size > 0 ? var.m_count : 0}"
  name  = "${var.name_prefix}-extra-${format("%03d", count.index)}"
  size  = "${var.extra_disk_size}"
}

# Attach extra disk (if created) Disk attaches as /dev/
resource "openstack_compute_volume_attach_v2" "attach_extra_disk" {
  count       = "${var.extra_disk_size > 0 ? var.m_count : 0}"
  instance_id = "${element(openstack_compute_instance_v2.instance.*.id, count.index)}"
  volume_id   = "${element(openstack_blockstorage_volume_v2.extra_disk.*.id, count.index)}"
}

output "local_ip_v4" {
  value = "${openstack_compute_instance_v2.instance.*.network.0.fixed_ip_v4}"
}

output "public_ip" {
  value = "${openstack_compute_floatingip_v2.floating_ip.*.address}"
}

output "hostnames" {
  value = "${openstack_compute_instance_v2.instance.*.name}"
}

# output "node_labels" {
#   value = "${var.node_labels}"
# }

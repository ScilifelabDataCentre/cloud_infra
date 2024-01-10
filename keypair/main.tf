terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.51.1"
    }
  }
}


variable name_prefix {}
variable public_key {}

# provider "openstack" {}

resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.name_prefix}-keypair"
  public_key = "${file(var.public_key)}"
}

output "keypair_name" {
  value = "${openstack_compute_keypair_v2.main.name}"
}

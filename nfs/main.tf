terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "network" {
  name      = "network"
  #mode      = "bridge"
  mode      = "nat"
  domain    = "otus.local"
  #bridge    = "br0"
  addresses = ["192.168.11.0/24"]
  dhcp {
    enabled    = true
  }

  dns {
    enabled    = true
    local_only = true
  }
}

resource "libvirt_pool" "pool" {
  name = "otus_pool"
  type = "dir"
  target {
    path = "/tmp/images"
  }
}

resource "libvirt_volume" "volume" {
  name     = "debian-12-otus.qcow2"
  pool     = libvirt_pool.pool.name
  source   = var.source_image
  format   = "qcow2"
}

resource "libvirt_volume" "volume2" {
  name     = "debian12-otus.qcow2"
  pool     = libvirt_pool.pool.name
  source   = var.source_image
  format   = "qcow2"
}
resource "libvirt_volume" "volume1" {
  name           = "volume1.qcow2"
  base_volume_id = libvirt_volume.volume.id
  size           = 4294967296
  pool           = libvirt_pool.pool.name
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = data.template_file.user_data.rendered
  pool      = libvirt_pool.pool.name
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    domain_name = "otus"
  }
}

terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "vpn-net" {
  name      = "network"
  #mode      = "bridge"
  mode      = "nat"
  domain    = "otus.local"
  #bridge    = "br0"
  addresses = ["192.168.50.0/24"]
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

resource "libvirt_volume" "os_image" {
  name     = "ubuntu-otus.qcow2"
  #pool     = libvirt_pool.pool.name
  source   = var.source_image
  format   = "qcow2"
}

resource "libvirt_volume" "volume" {
  #name           = "volume1.qcow2"
  name           = "vm_${count.index}.qcow2"
  pool           = libvirt_pool.pool.name
  base_volume_id = libvirt_volume.os_image.id
  size           = 8589934592
  format   = "qcow2"
  count          =  var.volume_count
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = data.template_file.user_data.rendered
  pool      = libvirt_pool.pool.name
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    domain_name = "local"
  }
}

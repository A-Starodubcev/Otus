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

resource "libvirt_volume" "volume1" {
  name           = "volume1.qcow2"
  base_volume_id = libvirt_volume.volume.id
  size           = 17179869184
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

resource "libvirt_domain" "server" {
  name = "debian12-otus"
  memory = "8192"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name = libvirt_network.network.name
    wait_for_lease = true #network interface gets a DHCP 
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = 0
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = 1
  }

  disk {
    volume_id = libvirt_volume.volume1.id
    scsi      = "true"
  }
  
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

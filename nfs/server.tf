resource "libvirt_domain" "server" {
  name = "debian12-otus-server"
  memory = "2048"
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


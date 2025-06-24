resource "libvirt_domain" "ns02" {
  name = "vm_ns02"
  memory = "1024"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_id     = libvirt_network.vpn-net.id
    hostname       = "ns02"
    addresses      = ["192.168.50.11"]
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
    volume_id = libvirt_volume.volume[1].id
    scsi      = "true"
  }
  
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}


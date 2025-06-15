resource "libvirt_domain" "client" {
  name = "ubuntu-client"
  memory = "4096"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_id     = libvirt_network.vpn-net.id
    hostname       = "client"
    addresses      = ["192.168.56.20"]
    mac            = "AA:BB:CC:11:14:7A"
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
    volume_id = libvirt_volume.volume2.id
    scsi      = "true"
  }
  
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}


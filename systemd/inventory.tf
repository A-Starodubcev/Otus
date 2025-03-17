
resource "local_file" "inventory" {

  content = <<-DOC
all:
  hosts:
    proxy:
      ansible_host: ${libvirt_domain.server.network_interface[0].addresses.0}

    DOC
  filename = "./playbook/inventory/hosts.yml"

}


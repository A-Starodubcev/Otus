
resource "local_file" "inventory" {

  content = <<-DOC
all:
  hosts:
    server:
      ansible_host: ${libvirt_domain.server.network_interface[0].addresses.0}
    client:
      ansible_host: ${libvirt_domain.client.network_interface[0].addresses.0}

    DOC
  filename = "./playbook/inventory/hosts.yml"

}


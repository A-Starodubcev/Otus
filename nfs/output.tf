output "server_ip" {
  value       = libvirt_domain.server.network_interface[0].addresses.0
  description = "Public ip"
}

output "client_ip" {
  value       = libvirt_domain.client.network_interface[0].addresses.0
  description = "Public ip"
}

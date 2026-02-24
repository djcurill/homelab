data "proxmox_virtual_environment_nodes" "available" {}

output "nodes" {
  value = data.proxmox_virtual_environment_nodes.available.names
}

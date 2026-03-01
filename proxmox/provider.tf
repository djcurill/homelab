provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006/api2/json"
  insecure = true

  ssh {
    agent       = false
    username    = var.proxmox_ssh_user
    private_key = file(pathexpand(var.proxmox_ssh_private_key_path))
  }
}

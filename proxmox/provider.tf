provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006/api2/json"
  insecure = true
}

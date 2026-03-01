variable "proxmox_host" {
  type = string
}

variable "proxmox_ssh_user" {
  type    = string
  default = "root"
}

variable "proxmox_ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "name" {
  type        = string
  description = "VM hostname"
}

variable "template_vm_id" {
  type        = number
  description = "VM ID of the template to clone"
}

variable "ip_address" {
  type        = string
  description = "Static IP with CIDR (e.g. 192.168.1.101/16)"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content"
}

variable "node_name" {
  type    = string
  default = "pve"
}

variable "gateway" {
  type    = string
  default = "192.168.0.1"
}

variable "dns_servers" {
  type    = list(string)
  default = ["1.1.1.1"]
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "cpu_type" {
  type    = string
  default = "host"
}

variable "memory_gb" {
  type        = number
  default     = 4
  description = "Memory in GB (converted to MB internally)"
}

variable "disk_size" {
  type        = number
  default     = 20
  description = "Disk size in GB"
}

variable "disk_datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "disk_interface" {
  type    = string
  default = "scsi0"
}

variable "init_datastore_id" {
  type        = string
  default     = "local"
  description = "Datastore for cloud-init config drive"
}

variable "username" {
  type    = string
  default = "ubuntu"
}

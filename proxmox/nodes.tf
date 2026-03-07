module "k3s_control_plane" {
  source         = "./modules/proxmox-vm"
  name           = "k3s-control-plane"
  template_vm_id = proxmox_virtual_environment_vm.ubuntu_template.vm_id
  ip_address     = "192.168.1.101/16"
  ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
}

module "k3s_worker_01" {
  source         = "./modules/proxmox-vm"
  name           = "k3s-worker-01"
  template_vm_id = proxmox_virtual_environment_vm.ubuntu_template.vm_id
  ip_address     = "192.168.1.102/16"
  ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
  memory_gb      = 6
  disk_size      = 40
}

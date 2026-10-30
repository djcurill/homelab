module "k3s_control_plane" {
  source         = "./modules/vm"
  name           = "k3s-cp-01"
  template_vm_id = proxmox_virtual_environment_vm.debian_trixie.vm_id
  ip_address     = "192.168.1.101/16"
  ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
  memory_gb = 4
  cpu_cores = 2
  disk_size = 30
}


module "k3s_worker_01" {
  source         = "./modules/vm"
  name           = "k3s-w-01"
  template_vm_id = proxmox_virtual_environment_vm.debian_trixie.vm_id
  ip_address     = "192.168.1.102/16"
  ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
  memory_gb      = 4
  disk_size      = 40
}

module "k3s_worker_02" {
  source         = "./modules/vm"
  name           = "k3s-w-02"
  template_vm_id = proxmox_virtual_environment_vm.debian_trixie.vm_id
  ip_address     = "192.168.1.103/16"
  ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
  memory_gb      = 4
  disk_size      = 40
}


resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name        = "ubuntu-24-04"
  description = "Ubuntu 24.04 Noble Numbat"
  tags        = ["ubuntu", "noble", "terraform"]

  # Creating a template
  template = true

  node_name = "pve"
  vm_id     = 9000

  # Set default CPU, this can be changed when spinning up clones
  cpu {
    cores = 2
    type  = "host"
  }

  # Set default memory, this can be changed when spinning up clones
  memory {
    dedicated = 4096
    floating  = 4096 # pin to 4Gb
  }

  # Set default disk settings, this can be changed when spinning up clones
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    size         = 20 # GB
  }

  # Network interface — plugs the VM into your network
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Cloud-init drive — so clones can receive hostname, IP, SSH key
  initialization {
    datastore_id = "local-lvm"
  }

  # Serial console — cloud images output to serial, not VGA
  serial_device {}

  boot_order = ["scsi0"]
}

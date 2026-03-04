# VM template — read-only master copy that K8s nodes are cloned from.
# Never booted directly. Clones inherit the disk and can override hardware settings.

resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name        = "ubuntu-24-04"
  description = "Ubuntu 24.04 Noble Numbat"
  tags        = ["ubuntu", "noble", "terraform"]

  template  = true  # locks VM as read-only, enables linked cloning
  node_name = "pve" # physical Proxmox host to create this on
  vm_id     = 9000  # high IDs (9000+) are convention for templates

  # Defaults — clones can override these per node
  cpu {
    cores = 2
    type  = "host" # passes real CPU features to VM, best perf for single-node
  }

  memory {
    dedicated = 4096
    floating  = 4096 # equal = balloon driver present but pinned (no dynamic shrinking)
  }

  # OS disk — cloud image imported as a logical volume on LVM
  disk {
    datastore_id = "local-lvm" # LVM thin provisioning, fast I/O for VM disks
    interface    = "scsi0"     # first slot on the virtio-scsi controller
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    size         = 20 # GB — thin provisioned, only uses real space as data is written
  }

  # Virtual NIC plugged into the Proxmox bridge (virtual switch)
  network_device {
    bridge = "vmbr0"  # connects VMs to the physical network
    model  = "virtio" # paravirtualized driver, fastest option for Linux
  }

  # Cloud-init config drive — clones fill in their own values (hostname, IP, SSH key)
  # Uses "local" because local-lvm doesn't support the qcow2 format this drive needs
  # Unsure if we need this still ...
  # initialization {
  #   datastore_id = "local"
  # }

  # Cloud images output to serial port, not VGA — without this the console is blank
  serial_device {}

  # Boot from OS disk, not network or cloud-init CD-ROM
  boot_order = ["scsi0"]
}

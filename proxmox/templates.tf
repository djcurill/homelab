# VM template — read-only master copy that K8s nodes are cloned from.
# Never booted directly. Clones inherit the disk and can override hardware settings.

resource "proxmox_virtual_environment_vm" "debian_trixie" {
  name        = "debian-13"
  description = "debian 13 trixie"
  tags        = ["template"]

  template  = true # locks VM as read-only, enables linked cloning
  started   = false
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
    file_id      = proxmox_download_file.debian_cloud_image.id
    size         = 20 # GB — thin provisioned, only uses real space as data is written
    discard      = "on"
    ssd          = true
    iothread     = true
  }

  // allocates a controller per disk (require iothread to be true in disk settings)
  scsi_hardware = "virtio-scsi-single"

  # Virtual NIC plugged into the Proxmox bridge (virtual switch)
  network_device {
    bridge = "vmbr0"  # connects VMs to the physical network
    model  = "virtio" # paravirtualized driver, fastest option for Linux
  }

  # Cloud images output to serial port, not VGA — without this the console is blank
  serial_device {}

  # must be installed first
  agent {
    enabled = false
  }

  # Boot from OS disk, not network or cloud-init CD-ROM
  boot_order = ["scsi0"]

  # Provider bug: template VMs always show changes for computed network attributes.
  # https://github.com/bpg/terraform-provider-proxmox/issues/1494
  # https://github.com/bpg/terraform-provider-proxmox/discussions/1992
  # lifecycle {
  #   ignore_changes = [ipv4_addresses, ipv6_addresses, network_interface_names]
  # }
}

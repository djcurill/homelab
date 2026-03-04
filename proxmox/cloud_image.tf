# Download Ubuntu 24.04 cloud image to Proxmox
#
# Cloud images are pre-installed OS disk images (not ISO installers).
# The file is actually qcow2 format but Ubuntu distributes it with a
# generic .img extension.

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "import" # disk image to import into a VM, not bootable media
  datastore_id = "local"  # directory-based store at /var/lib/vz/
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name    = "noble-server-cloudimg-amd64.qcow2"
}

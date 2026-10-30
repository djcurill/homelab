# Download Debian 13 (trixie) cloud image to Proxmox
#
# Cloud images are pre-installed OS disk images (not ISO installers).
# The file is actually qcow2 format but Ubuntu distributes it with a
# generic .img extension.

resource "proxmox_download_file" "debian_cloud_image" {
  content_type = "import" # disk image to import into a VM, not bootable media
  datastore_id = "local"  # directory-based store at /var/lib/vz/
  node_name    = "pve"

  url       = "https://cloud.debian.org/images/cloud/trixie/20261026-2643/debian-13-genericcloud-amd64-20261026-2643.qcow2"
  file_name = "debian-13-genericcloud-amd64-20261026-2643.qcow2"

  checksum_algorithm = "sha512"
  checksum           = "3ace18e33bdd036edb49d1f79342bd01d2ab980e35194edb0b410435cd543538d286a0bd13bbb0835f7862306e3d385ce2f6a70d8ecf0bd961111166adbc1b8e"
}

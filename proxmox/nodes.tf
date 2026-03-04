# Cloud-init user data snippet — rendered per clone with unique hostname.
# Uploaded to Proxmox "local" storage as a snippet (small config file).
# templatefile() injects variables into the .tpl file at plan time.
resource "proxmox_virtual_environment_file" "k3s-control-plane" {
  datastore_id = "local"
  node_name    = "pve"
  content_type = "snippets" # must be enabled on the datastore in Proxmox UI

  source_raw {
    data = templatefile("cloud-init/user-data.yaml.tpl", {
      hostname       = "k3s-control-plane"
      username       = "ubuntu"
      ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
    })
    file_name = "user-data-k3s-control-plane.yaml"
  }
}

# K8s control plane node — cloned from template, not built from scratch.
# Disk is inherited from the template via clone block.
resource "proxmox_virtual_environment_vm" "k3s_control_plane" {
  name      = "k3s-control-plane"
  node_name = "pve"

  # Clone from the template
  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template.vm_id
  }

  # QEMU guest agent — allows Proxmox to see VM IP, graceful shutdown, etc.
  # Requires qemu-guest-agent to be installed inside the VM (done via cloud-init)
  agent {
    enabled = true
  }

  # Cloud-init config unique to this node
  # user_data_file_id handles user/SSH key setup
  initialization {
    user_data_file_id = proxmox_virtual_environment_file.k3s-control-plane.id
    file_format       = "raw" # required for local-lvm compatibility

    ip_config {
      ipv4 {
        address = "192.168.1.101/16" # static IP, outside DHCP range to avoid conflicts
        gateway = "192.168.0.1"      # Eero router
      }
    }

    dns {
      servers = ["1.1.1.1"] # Cloudflare
    }
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
    floating  = 4096
  }

  # Disk inherited from template — only specify overrides (e.g. size)
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20 # GB
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
}

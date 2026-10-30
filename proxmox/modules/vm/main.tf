resource "proxmox_virtual_environment_file" "cloud_init" {
  datastore_id = "local"
  node_name    = var.node_name
  content_type = "snippets"

  source_raw {
    data = templatefile("${path.module}/files/user-data.yaml.tpl", {
      hostname       = var.name
      username       = var.username
      ssh_public_key = var.ssh_public_key
    })
    file_name = "user-data-${var.name}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name

  clone {
    vm_id = var.template_vm_id
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id      = var.init_datastore_id
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_gb * 1024
    floating  = var.memory_gb * 1024
  }

  disk {
    datastore_id = var.disk_datastore_id
    interface    = var.disk_interface
    size         = var.disk_size
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
}

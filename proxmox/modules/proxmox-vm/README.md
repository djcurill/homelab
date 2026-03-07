# proxmox-vm module

Creates a Proxmox VM cloned from a template with cloud-init configuration.

Handles both the cloud-init snippet upload and the VM resource, so adding a new node is ~10 lines.

## Usage

```hcl
module "my_vm" {
  source         = "./modules/proxmox-vm"
  name           = "my-vm"
  template_vm_id = proxmox_virtual_environment_vm.ubuntu_template.vm_id
  ip_address     = "192.168.1.110/16"
  ssh_public_key = trimspace(data.local_file.ssh_public_key.content)

  # Optional overrides (shown with defaults)
  memory_gb = 4
  disk_size = 20
  cpu_cores = 2
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | string | required | VM hostname |
| `template_vm_id` | number | required | VM ID of the template to clone |
| `ip_address` | string | required | Static IP with CIDR (e.g. `192.168.1.101/16`) |
| `ssh_public_key` | string | required | SSH public key content |
| `node_name` | string | `"pve"` | Proxmox node |
| `gateway` | string | `"192.168.0.1"` | Default gateway |
| `dns_servers` | list(string) | `["1.1.1.1"]` | DNS servers |
| `cpu_cores` | number | `2` | CPU cores |
| `cpu_type` | string | `"host"` | CPU type |
| `memory_gb` | number | `4` | Memory in GB (converted to MB internally) |
| `disk_size` | number | `20` | Disk size in GB |
| `disk_datastore_id` | string | `"local-lvm"` | Datastore for VM disk |
| `disk_interface` | string | `"scsi0"` | Disk interface |
| `init_datastore_id` | string | `"local"` | Datastore for cloud-init config drive |
| `username` | string | `"ubuntu"` | Cloud-init user |

## Outputs

| Name | Description |
|------|-------------|
| `vm_id` | Proxmox VM ID |
| `name` | VM hostname |
| `ip_address` | Static IP (as provided) |

## Cloud-init

The module includes its own cloud-init template at `files/user-data.yaml.tpl`. Cloud-init only runs on first boot — changes require destroying and recreating the VM.

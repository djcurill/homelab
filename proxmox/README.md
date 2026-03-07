# Proxmox Terraform

Manages VMs on a single-node Proxmox cluster.

## Structure

```
proxmox/
  cloud_image.tf        # Downloads Ubuntu cloud image
  data.tf               # Data sources (SSH key)
  nodes.tf              # VM definitions using the proxmox-vm module
  provider.tf           # Proxmox provider config
  templates.tf          # Ubuntu VM template (base image for clones)
  variables.tf          # Root-level variables
  versions.tf           # Terraform and provider versions
  modules/
    proxmox-vm/         # Reusable module for cloned VMs with cloud-init
      files/
        user-data.yaml.tpl
```

## Adding a new VM

Add a module block to `nodes.tf`:

```hcl
module "my_new_vm" {
  source         = "./modules/proxmox-vm"
  name           = "my-new-vm"
  template_vm_id = proxmox_virtual_environment_vm.ubuntu_template.vm_id
  ip_address     = "192.168.1.110/16"
  ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
  memory_gb      = 8
  disk_size      = 50
}
```

See [modules/proxmox-vm/README.md](modules/proxmox-vm/README.md) for all available inputs.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Requires `proxmox_host` variable — set via `terraform.tfvars` or `-var`.

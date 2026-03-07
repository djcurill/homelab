#cloud-config
# This line is required — tells cloud-init to parse this as YAML config.
# Rendered by Terraform templatefile() with per-clone variables.
# Cloud-init only runs on FIRST BOOT — changes require destroying and recreating the VM.

hostname: ${hostname}
package_update: true
packages:
  - qemu-guest-agent # enables Proxmox-to-VM communication (IP reporting, graceful shutdown)

users:
  - name: ${username}
    sudo: (ALL) NOPASSWD:ALL    # full sudo without password prompts
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}       # injected from ~/.ssh/id_rsa.pub via Terraform

runcmd:
  - systemctl enable --now qemu-guest-agent # enable = start on boot, --now = also start immediately

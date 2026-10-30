# Ansible

We will use ansible to manage proxmox VMs.

## Setup

Ansible is a python library, and so we will use `uv` to mange the python dependencies.

```bash
uv venv --python 3.14
uv pip install ansible
```

## Inventory

We use the `inventory.yml` to configure connections to single servers and/or groups of servers. For a cluster, we have our `workers` and our `control_plane`. We can ping a specific group to test connectivity with:

```bash
ansible control_plan -m ping
```

## Adhoc Commands

```bash
# get the hostnames
ansible cluster -m command -a "hostname"
```

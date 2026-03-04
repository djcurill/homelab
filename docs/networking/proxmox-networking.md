# Proxmox Networking

## Overview

Understanding Proxmox networking is foundational to running VMs, building a
Kubernetes cluster, and eventually segmenting your homelab into clean,
isolated networks.

---

## The Physical Layer

A Proxmox host is a physical machine with a **NIC** (Network Interface Card)
— the port where an ethernet cable plugs in. Linux names these devices
something like `eth0` or `eno1`.

The problem: you have one physical NIC but want many VMs to have network
access. The solution is a **bridge**.

---

## Linux Bridges (`vmbr0`)

A **Linux bridge** is a virtual network switch that lives entirely in
software. Proxmox creates `vmbr0` automatically on install and bridges it to
your primary NIC.

```
Internet
    │
Your Router
    │
Physical Switch
    │
Proxmox Host NIC (eno1)
    │
vmbr0 (Linux Bridge — virtual switch)
    ├── Proxmox Host
    ├── VM 1
    ├── VM 2
    └── VM 3
```

Every VM plugs into `vmbr0`, and it forwards traffic between VMs and out to
your physical network through the NIC. Think of it as a network switch built
into software.

---

## VM Network Interface (`--net0 virtio,bridge=vmbr0`)

When creating a VM, this argument defines its network interface:

```
--net0 virtio,bridge=vmbr0
  │     │        │
  │     │        └── which bridge to connect to
  │     └── driver type (virtio = fast, paravirtualized)
  └── first network interface slot (net0, net1, net2...)
```

### Driver Types

| Driver    | Speed      | Use Case                              |
|-----------|------------|---------------------------------------|
| `virtio`  | Fastest    | Always use this for Linux VMs         |
| `e1000`   | Slower     | Legacy or Windows VMs                 |
| `rtl8139` | Slowest    | Very old VMs only                     |

`virtio` is **paravirtualized** — the VM knows it's virtual and uses an
optimized path rather than emulating real hardware. Always use it for Linux.

---

## IP Addressing: DHCP vs Static

Once a VM is on the bridge, it needs an IP address.

### DHCP
The VM asks the router for an IP automatically.
- Easy to set up
- IP can change on reboot — **bad for Kubernetes nodes**

### Static IP
A fixed IP assigned at creation time via cloud-init.
- Requires planning your IP space
- **Essential for Kubernetes nodes** which must always find each other

Cloud-init configuration example:

```yaml
ipconfig0: ip=192.168.1.10/24,gw=192.168.1.1
nameserver: 1.1.1.1
```

| Part                | Meaning                                           |
|---------------------|---------------------------------------------------|
| `ip=192.168.1.10`   | The VM's IP address                               |
| `/24`               | Subnet mask (covers 192.168.1.0–192.168.1.255)    |
| `gw=192.168.1.1`    | Gateway — your router, how the VM reaches internet|
| `nameserver`        | DNS server — resolves domain names to IPs         |

---

## VLANs

A **VLAN** (Virtual LAN) logically separates networks on the same physical
hardware. Without VLANs, everything on `vmbr0` is one flat network — all
VMs, your laptop, your phone, everything can talk to each other.

```
Physical switch (one cable to Proxmox)
├── VLAN 10 → Home devices (phones, laptops)
├── VLAN 20 → Homelab VMs / Kubernetes
└── VLAN 30 → IoT devices (Home Assistant, sensors)
```

### Why VLANs Matter
- **Security** — IoT devices can't reach your Kubernetes cluster
- **Organization** — clean separation of concerns
- **Realistic** — mirrors how real infrastructure is designed

### Assigning a VLAN to a VM

```bash
--net0 virtio,bridge=vmbr0,tag=20
```

The `tag=20` tells the bridge this VM belongs to VLAN 20.

> **Note:** VLANs require your router/switch to support VLAN tagging.
> Not all home routers do. VLANs are not required to get started.

---

## Kubernetes Networking Requirements

Kubernetes nodes need:

1. **Stable IPs** — static addresses so nodes always find each other
2. **Same network** — all nodes must communicate freely
3. **Outbound internet** — to pull container images from registries

### Example Cluster IP Plan

```
Subnet: 192.168.20.0/24 (VLAN 20)

k3s-control-plane   192.168.20.10
k3s-worker-1        192.168.20.11
k3s-worker-2        192.168.20.12
```

Each VM gets its IP assigned via cloud-init at clone time. They share the
same subnet so they can reach each other directly.

---

## Things to Check in Your Environment

- **Does your router support VLANs?** — Not required to start, useful later.
- **What is your home subnet?** — Common ones: `192.168.1.x`, `10.0.0.x`.
  Knowing this determines what IPs you assign your nodes.
- **Can you reserve IPs in your router's DHCP?** — Even with static IPs in
  VMs, ensure your router doesn't accidentally assign those IPs to other
  devices.

---

## Related Topics

- [Proxmox Cloud Image Templates](./proxmox-cloud-image-templates.md)
- Kubernetes internal networking (CNI plugins, pod networking)
- DNS in a homelab (Pi-hole, CoreDNS)

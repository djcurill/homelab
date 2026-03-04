# Home Network Reference

Reference document for the home network environment. Update this as your
setup changes.

---

## Hardware

| Device   | Model  |
|----------|--------|
| Router   | Eero 6 |

---

## Network

| Setting          | Value                         |
|------------------|-------------------------------|
| Subnet           | `192.168.0.0/16`              |
| Router / Gateway | `192.168.0.1`                 |
| DNS              | `1.1.1.1` (Cloudflare)        |
| DHCP Range       | `192.168.0.20–192.168.0.254`  |

---

## Proxmox Host

| Setting  | Value                          |
|----------|--------------------------------|
| IP       | `192.168.1.100`                |
| Web UI   | `https://192.168.1.100:8006`   |

---

## Reserved IPs (Static Assignments)

Devices that need stable IPs should be listed here. This prevents your router
from accidentally assigning those IPs to other devices via DHCP.

> **Tip:** Keep your static IPs **outside** the DHCP range
> (`192.168.0.20–192.168.0.254`) to avoid conflicts. Addresses like
> `192.168.0.2–192.168.0.19` are safe to use for static assignments.

| Hostname           | IP              | Role                    |
|--------------------|-----------------|-------------------------|
| proxmox            | `192.168.1.100` | Hypervisor               |
| k3s-control-plane  | `192.168.1.101` | Kubernetes control plane |
| k3s-worker-1       | `192.168.1.102` | Kubernetes worker        |
| k3s-worker-2       | `192.168.1.103` | Kubernetes worker        |

---

## Notes

- DHCP is managed by the Eero 6
- Cloudflare DNS (`1.1.1.1`) is used for privacy and reliability

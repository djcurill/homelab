# Proxmox Cloud Image Templates

A deep dive into every concept involved in creating a cloud image template
in Proxmox using Terraform.

---

## What is a Terraform Resource?

Terraform works with **resources** — each resource represents one piece of
infrastructure that Terraform creates and manages. A VM, a downloaded file,
a DNS record — each is a resource.

Every resource has two names:

- **Resource type** — defined by the provider (e.g.
  `proxmox_virtual_environment_vm`). You can't change this. It tells
  Terraform what kind of thing to create.
- **Local name** — chosen by you (e.g. `ubuntu_template`). This is how you
  reference the resource elsewhere in your Terraform code.

When you write:

```hcl
resource "proxmox_virtual_environment_vm" "ubuntu_template" { ... }
```

You're saying: "create a Proxmox VM, and I'll call it `ubuntu_template`
internally." Other resources can reference it as
`proxmox_virtual_environment_vm.ubuntu_template`.

Terraform reads ALL `.tf` files in a directory, builds a **dependency graph**
from the references between resources, and creates everything in the correct
order automatically. File names and resource order within files don't matter.

---

## Templates

A template in Proxmox is a **VM that has been converted to read-only mode**.
There is no separate "template" object — it's just a regular VM with a flag
set.

When `template = true` is set:

- The VM is locked. You cannot boot it, modify its disks, or change its
  state.
- The Proxmox UI changes the icon and removes the "Start" button.
- The "Clone" option becomes available.
- **Linked cloning** is enabled — clones don't copy the full disk. They
  store a reference to the template's disk and only record the differences.
  This saves significant disk space.

The template exists solely to be cloned. You build it once (download cloud
image, configure hardware, set up cloud-init) and then every future VM starts
from that identical base.

Under the hood, `template = true` in Terraform triggers the equivalent of
`qm template <vm_id>` on the Proxmox host after the VM is fully configured.

---

## Node Name

Proxmox is designed to run as a **cluster** of physical machines. Each
physical machine in the cluster is called a **node**. Even a single-server
setup is still a cluster of one node.

When you installed Proxmox, it asked for a hostname. The default is `pve`
(Proxmox Virtual Environment). That hostname becomes the node name.

Every Terraform resource that creates something on Proxmox needs
`node_name` — it tells Proxmox which physical machine to put the resource
on. In a multi-node cluster, different VMs could live on different physical
machines. In a single-node setup like yours, everything goes to the same
node.

The node name is visible in the Proxmox web UI as the first item under
"Datacenter" in the left sidebar.

---

## VM ID

Every VM in Proxmox has a unique numeric ID. This is how Proxmox internally
tracks and references VMs — in API calls, file paths, storage volumes,
and log entries.

Convention:

- **100–899** — regular VMs and containers
- **900–999** — sometimes used for special purpose VMs
- **9000+** — commonly used for templates

The convention is just a community practice, not a technical requirement.
Proxmox only cares that each ID is unique within the cluster.

When you set `vm_id = 9000`, you're reserving that ID for your template.
Clones will get their own IDs (assigned automatically or specified manually).

VM IDs map directly to storage. A VM with ID 9000 gets its disk stored as
`vm-9000-disk-0` in the datastore. This naming is automatic and consistent.

---

## CPU Virtualization

When a VM runs, it doesn't execute directly on your physical CPU. **QEMU**
(the virtualization software Proxmox uses) sits in between and presents a
**virtual CPU** to the VM.

The CPU type controls which features of your physical CPU are visible to the
VM. Every x86-64 CPU has a set of **feature flags** — capabilities like
encryption acceleration (AES-NI), vector processing (AVX), and various
instruction set extensions.

### CPU Types

**`kvm64`** — the Proxmox default. Exposes a minimal 64-bit CPU with almost
no modern features. Maximum compatibility but worst performance. The VM
can't use hardware AES, AVX, or most optimizations your physical CPU
supports.

**`x86-64-v2`** — exposes features from ~2009-era CPUs: SSE3, SSE4.1,
SSE4.2, POPCNT. A reasonable baseline.

**`x86-64-v2-AES`** — same as v2 plus hardware AES-NI encryption
acceleration. Important for any workload using TLS/SSL (which includes
all Kubernetes cluster communication).

**`x86-64-v3`** — exposes features from ~2013-era CPUs: AVX, AVX2, BMI1,
BMI2, FMA. Significantly more compute capability for numerical workloads.

**`x86-64-v4`** — exposes AVX-512 from ~2017-era CPUs. Only use if your
physical CPU actually has AVX-512.

**`host`** — passes your actual physical CPU directly through to the VM with
all its features. No emulation, no feature masking. The VM sees exactly
what your hardware provides.

### The Portability Trade-off

The reason different types exist is **live migration**. If you have multiple
Proxmox nodes with different CPUs (say an Intel and an AMD), a VM configured
with `type = "host"` on the Intel node can't migrate to the AMD node — it
expects Intel-specific features that don't exist on AMD.

By using a standardized type like `x86-64-v2-AES`, you're telling the VM:
"only use features that ALL my nodes support." This makes migration safe.

For a single-node setup, migration is impossible anyway, so `host` gives
you the best performance with no downside.

### Cores

`cores` sets how many virtual CPU cores the VM sees. The VM's operating
system schedules processes across these cores just like a physical machine
would.

Virtual cores map to **threads** on your physical CPU. If your physical
CPU has 16 threads, you could theoretically assign 16 cores to a single VM,
but that would starve the Proxmox host and other VMs. A good rule of thumb
is to not overcommit CPU by more than 2:1 across all VMs.

---

## Memory Virtualization

When a VM is created, Proxmox reserves a block of the host's physical RAM
for that VM. The VM sees this as its entire memory space — it has no
knowledge of the host or other VMs.

### Dedicated Memory

`dedicated` is the amount of RAM (in megabytes) guaranteed to the VM. This
memory is reserved from the host's physical RAM when the VM starts.

### Floating Memory and Ballooning

**Memory ballooning** is a technique where a VM can dynamically give back
unused memory to the host. A special driver inside the VM (the balloon
driver) "inflates" to consume memory inside the VM, effectively making that
memory unavailable to the VM's processes. The host then reclaims that
physical RAM for other uses.

The `floating` parameter controls whether the balloon driver is present
and what the minimum memory can be:

- **`floating` not set** — no balloon driver installed. The VM always has
  exactly `dedicated` MB. Ballooning is completely off.
- **`floating` < `dedicated`** — balloon driver is active. Memory can shrink
  down to `floating` MB when the VM is idle. For example,
  `dedicated = 4096, floating = 2048` means the VM has 4GB max but can
  shrink to 2GB.
- **`floating` = `dedicated`** — balloon driver is present but pinned. The
  minimum equals the maximum, so memory can never actually shrink. The
  driver exists but has no room to move.

### Why Pin Memory for Kubernetes

Kubernetes has its own scheduler that decides where to place workloads based
on how much memory each node reports. If ballooning silently shrinks a
node's memory from 4GB to 2GB, Kubernetes doesn't know — it still thinks
the node has 4GB available. This causes the scheduler to place more
workloads than the node can handle, leading to OOM (Out of Memory) kills.

Setting `dedicated = floating` ensures the memory is stable and predictable.
Kubernetes can trust the reported memory and schedule correctly.

---

## Virtual Disks

A virtual disk is a file or logical volume on the Proxmox host that
appears as a physical hard drive to the VM. The VM's operating system sees
a standard disk device and interacts with it normally — it has no idea the
disk is virtual.

### Datastore

`datastore_id` determines where the virtual disk is stored on the Proxmox
host.

**`local`** — a directory-based store at `/var/lib/vz/` on the Proxmox
host. Stores files you can browse: ISOs, cloud images, snippets, container
templates. Used for downloads and imports.

**`local-lvm`** — an LVM-based store that manages disk space as logical
volumes. VM disks live here. Logical volumes are not regular files — you
can't browse them in a file manager. They're raw block devices managed by
LVM, which provides thin provisioning and efficient I/O.

Cloud images are downloaded to `local` (as files), then imported into
`local-lvm` (as logical volumes) when attached to a VM.

### Disk Interface and SCSI

`interface = "scsi0"` specifies two things in one value:

The **controller type** (`scsi`) — this is the disk controller, the
interface between the VM's operating system and the virtual disk. Proxmox
supports several controller types:

- `scsi` — fastest option when paired with the `virtio-scsi-pci` controller
  hardware. The controller is paravirtualized (the VM knows it's virtual and
  uses an optimized code path).
- `virtio` — also paravirtualized and fast. An alternative to scsi.
- `sata` — emulates a standard SATA controller. Slower but compatible with
  more operating systems.
- `ide` — emulates an old IDE controller. Slowest, used only for legacy
  systems or small utility drives (like the cloud-init drive).

The **slot number** (`0`) — which port on the controller the disk is
plugged into. Think of it like SATA ports on a motherboard:

```
virtio-scsi-pci controller
├── scsi0  ← primary OS disk
├── scsi1  ← second disk (if needed)
├── scsi2  ← third disk
└── ...
```

`scsi0` is always the primary boot disk by convention.

### File ID

`file_id` links the disk to the downloaded cloud image. This reference
creates an implicit dependency in Terraform's dependency graph — Terraform
knows it must download the cloud image before it can create this disk.

The cloud image is a pre-installed Ubuntu filesystem in qcow2 format. When
Proxmox creates the VM disk, it imports this image as the starting content
of the logical volume. The result is a bootable disk with Ubuntu already
installed.

### Size

`size` is the total capacity of the virtual disk in gigabytes. The cloud
image occupies a small portion (~2-3GB of actual data), and the rest is
available for the operating system to use as it runs.

LVM uses **thin provisioning** — a 20GB logical volume doesn't consume 20GB
of physical disk space immediately. Space is allocated only as data is
actually written. A VM with a 20GB disk that only has 3GB of data uses
approximately 3GB of real storage.

When cloning a template, the clone's disk size can be increased but never
decreased below the template's size. The template size is the minimum for
all clones.

---

## Network Device

VMs need a network interface to communicate with other machines. The
`network_device` block adds a virtual NIC (Network Interface Card) to the
VM.

### Bridge

`bridge = "vmbr0"` connects the VM's virtual NIC to a **Linux bridge** on
the Proxmox host. A bridge is a software-defined network switch.

Proxmox creates `vmbr0` during installation and connects it to the host's
physical NIC. Every VM plugged into `vmbr0` can reach:

- Other VMs on the same bridge
- The Proxmox host itself
- Your physical network (router, other devices)
- The internet (through your router)

The bridge forwards Ethernet frames between all connected interfaces, just
like a physical network switch.

### Model

`model = "virtio"` sets the virtual NIC's driver type.

**virtio** is a **paravirtualized** network driver. In traditional
virtualization, QEMU emulates a real network card (like an Intel e1000) —
the VM thinks it's talking to physical hardware, and QEMU translates those
hardware commands into actual network operations. This translation is slow.

Paravirtualization skips the hardware emulation. The VM knows it's virtual
and uses an optimized interface to communicate directly with the hypervisor.
This is significantly faster — lower latency, higher throughput.

Always use `virtio` for Linux VMs. The only reason to use `e1000` or
`rtl8139` is for operating systems that don't have virtio drivers (some old
Windows versions).

---

## Cloud-Init Initialization

Cloud-init is a tool that runs inside the VM on first boot and automatically
configures the operating system. It's baked into cloud images — you don't
install it yourself.

### How Cloud-Init Receives Configuration

Cloud-init needs a delivery mechanism to receive its configuration. In
Proxmox, this is a small virtual drive (typically an IDE CD-ROM) that
contains the configuration data in a specific format.

The `initialization` block in the template tells Proxmox to add this drive
and specifies which datastore to create it on. In the template, you only set
up the drive slot — no actual configuration values. The clones fill in
their own values (hostname, IP, SSH key) which get written to their own
copy of this drive.

### What Cloud-Init Does on First Boot

When a clone boots for the first time:

1. The operating system starts normally
2. Cloud-init detects the configuration drive
3. It reads the configuration data (hostname, users, SSH keys, network
   settings)
4. It applies the configuration to the running system
5. It marks itself as complete so it doesn't re-run on subsequent boots

This is what makes cloud images powerful — you create one base image and
customize each instance at boot time through configuration rather than
manual setup.

### What Cloud-Init Can Configure

- **Hostname** — the machine's network name
- **User accounts** — create users, set passwords, configure sudo
- **SSH keys** — inject public keys for passwordless authentication
- **Network** — set static IPs, DNS servers, gateways
- **Package installation** — install additional software on first boot
- **Custom scripts** — run arbitrary commands on first boot

---

## Serial Device

Cloud images are designed to run **headless** — without a monitor or
graphical display. They're built for cloud environments where you never
physically look at a screen.

Instead of outputting to a VGA display (what you'd see on a monitor),
cloud images output their boot logs and console to a **serial port**. A
serial port is a simple text-based communication channel — think of it as
a text stream from the VM.

Adding `serial_device {}` to the VM creates a virtual serial port. The
cloud image's kernel is already configured to output to this port. Proxmox
can then connect to this serial port and display the output in its web-based
console (via xterm.js instead of noVNC).

Without a serial device, the Proxmox console connects via VGA/noVNC and
shows a blank screen — the cloud image is outputting text, but to a serial
port that doesn't exist.

---

## Boot Order

When a computer starts, the firmware (BIOS or UEFI) needs to know which
device to boot from. It checks devices in a specific order until it finds
one with a bootable operating system.

A VM can have multiple bootable devices:

- `scsi0` — the OS disk (Ubuntu cloud image)
- The cloud-init CD-ROM
- The network interface (PXE boot)

`boot_order = ["scsi0"]` tells the VM firmware: "boot from the SCSI disk
at slot 0, and don't try anything else." Without this:

- The VM might try to PXE boot over the network (waiting for a network
  boot server that doesn't exist)
- It might try to boot from the cloud-init CD-ROM (which has no operating
  system)
- The boot order might be unpredictable across reboots

Explicitly setting the boot order eliminates ambiguity.

---

## How It All Connects

The full dependency chain across your Terraform files:

```
cloud_image.tf
  Downloads the Ubuntu cloud image (.img file renamed to .qcow2)
  to the "local" datastore on your Proxmox node.
       │
       │  file_id reference
       ↓
templates.tf
  Creates a VM with the cloud image as its disk, adds networking,
  cloud-init drive, serial console, and boot order. Marks it as
  a template (read-only, cloneable).
       │
       │  clone { vm_id } reference
       ↓
nodes.tf
  Creates 3 VMs by cloning the template. Each clone gets unique
  cloud-init values: hostname, static IP, and SSH key. Disk and
  memory can be overridden per clone.
```

Terraform resolves these references automatically, determines the correct
creation order, and executes accordingly. If the cloud image changes (new
Ubuntu version), Terraform will detect the change, rebuild the template,
and recreate the clones.

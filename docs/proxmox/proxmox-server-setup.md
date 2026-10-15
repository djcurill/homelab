# Server Setup

This document documents steps perfomed on the proxmox server for proper setup or quality of life improvements.

## Remove enterprize source files

The server ran into 401 authorization errors when trying to run routine `apt-get update` jobs. These enterprise `.sources` entries should be delete because we are using the free version.

```bash
rm /etc/apt/sources.list.d/pve-enterprise.source
rm /etx/apt/sources.list.d/ceph.sources
```

## `xterm-ghostty` not recognized

I use ghostty on my Mac, but the terminfo is often unrecognized in debian based OS. The official docs for ghostty recognize this and provide a 1 liner solution:

```bash
infocmp -x xterm-ghostty | ssh YOUR-SERVER -- tic -x -
```



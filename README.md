# iPXE

Test iPXE config to run Fedora CoreOS (fcos) or Flatcar Linux on Equinix Metal

Currently this iPXE boot loads Fedora CoreOS or Flatcar Linux into RAM, provisions the 2 disks as RAID1 under /var/lib/data and starts an nginx container.

Tested on c3.small.x86

NOTE: This repository is meant for testing and might contain invalid/broken code at any point.

## ipxe urls

- Fedora CoreOS: http://ipxe.thomasvdw.com/fcos/
- Flatcar Linux: http://ipxe.thomasvdw.com/flatcar/

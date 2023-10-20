# iPXE

Test iPXE config to run Fedora CoreOS (fcos) or Flatcar on Equinix Metal

Currently this iPXE boot loads Fedora CoreOS or Flatcar into RAM, provisions the 2 disks as RAID1 under /var/lib/data and starts an nginx container.

Tested on c3.small.x86

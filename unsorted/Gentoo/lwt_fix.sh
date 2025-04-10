#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script using sudo."
  exit
fi

# lwt dependency fails to compile because ppxlib is pulled in as a binary
emerge -vq --keep-going app-emulation/guestfs-tools 
re-emerge dev/ppxlib from source
FEATURES="-getbinpkg" emerge -1Dvq dev-ml/ppxlib
lwt will now compile properly, allowing guestfs-tools to finish compiling
emerge -vq --keep-going app-emulation/guestfs-tools 

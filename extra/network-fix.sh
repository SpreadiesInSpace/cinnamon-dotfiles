#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script must NOT be run as root. Please execute it as a regular user."
  exit
fi

# Disable autostart of the default network
virsh net-autostart default --disable

# Ask the user if they want to reboot
read -p "Do you want to reboot now? (y/n): " response
if [[ "$response" =~ ^[Yy]$ ]]; then
  reboot
else
  echo "Reboot canceled. Please reboot manually when needed."
fi


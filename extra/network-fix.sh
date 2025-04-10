#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script using sudo."
  exit
fi

# Disable autostart of the default network
virsh net-autostart default --disable

# Ask the user if they want to reboot
read -p "Do you want to reboot now? [y/N]: " response
if [[ "$response" =~ ^[Yy]$ ]]; then
  reboot
else
  echo "Reboot canceled. Please reboot manually when needed."
fi


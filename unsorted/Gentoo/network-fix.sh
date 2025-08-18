#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
	echo "Please run the script using sudo."
	exit
fi

# Disable autostart of the default network
virsh net-destroy default
virsh net-autostart default --disable

# Too lazy to set conditions, just run them all
systemctl restart libvirtd
/etc/rc.d/rc.libvirt restart
sv restart libvirtd

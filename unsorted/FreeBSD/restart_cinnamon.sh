#!/usr/local/bin/bash
cinnamon-dbus-command RestartCinnamon 1

# Open Nemo with the specified Samba share
nemo smb://192.168.1.127/Share

# Wait for 10 seconds
sleep 10

# Removes core files, screenshots and old xsession error logs
./cleanup.sh


#!/bin/bash

# Double Font Size
setfont -d

# Simple Dynamic Timer
while true; do
    clear
    lsblk
    echo
    uptime -p
    sleep 60
done

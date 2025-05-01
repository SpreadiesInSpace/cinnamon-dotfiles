#!/bin/bash

# Reset to default console font (portable fallback)
if setfont -d &>/dev/null; then
    setfont -d
elif [ -f /usr/share/kbd/consolefonts/default8x16.psfu.gz ]; then
    setfont /usr/share/kbd/consolefonts/default8x16.psfu.gz
elif [ -f /usr/share/consolefonts/default8x16.psfu.gz ]; then
    setfont /usr/share/consolefonts/default8x16.psfu.gz
else
    echo "Default font not found; skipping setfont."
fi

# Function to show uptime with fallback
show_uptime() {
    if uptime -p &>/dev/null; then
        uptime -p
    else
        uptime
    fi
}

# Simple Dynamic Timer
while true; do
    clear
    lsblk
    echo
    show_uptime
    sleep 60
done

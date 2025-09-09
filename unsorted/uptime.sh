#!/bin/bash

# Reset to default console font (if successful, font doubles in size)
setfont -d

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

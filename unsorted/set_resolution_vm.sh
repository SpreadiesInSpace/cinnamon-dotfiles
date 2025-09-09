#!/bin/bash

# VM Prompt
read -rp "Is this a Virtual Machine? [y/N]: " response
if [[ "$response" =~ ^[Yy]$ ]]; then
  is_vm=true
  # Detect connected output using sysfs (no X required)
  output_path=$(grep -l connected /sys/class/drm/*/status | head -n1)
  output=$(basename "$(dirname "$output_path")")
  output="${output#*-}"  # Strip 'cardX-' prefix
  if [[ -n "$output" ]]; then
    echo "Setting resolution to 1920x1080 for $output..."
    xrandr --output "$output" --mode 1920x1080 --rate 60
    # Create autostart entry to persist resolution after login
    mkdir -p /home/"$username"/.config/autostart
    cat <<EOF > /home/"$username"/.config/autostart/set-resolution.desktop
[Desktop Entry]
Type=Application
Exec=xrandr --output $output --mode 1920x1080 --rate 60
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Set Resolution
Comment=Set display resolution at login
EOF
    chown "$username:$username" /home/"$username"/.config/autostart/set-resolution.desktop
  fi
else
  is_vm=false
fi

#!/bin/bash

# Set SDDM to automatically log in into the Cinnamon session
if [ "$enable_autologin" = true ]; then
		sed -i '/^\[Autologin\]/,/^\[/ {
			s/^User=[[:space:]]*$/User='"$username"'/;
			s/^Session=[[:space:]]*$/Session=cinnamon/;
			s/^User=.*$/User='"$username"'/;
			s/^Session=.*$/Session=cinnamon/;
		}' /etc/sddm.conf
fi

# If running in a VM, append display resolution setup to SDDM's Xsetup script
if [ "$is_vm" = true ]; then
		# Detect connected output using sysfs (avoids X dependency)
		output_path=$(grep -l connected /sys/class/drm/*/status | head -n1)
		output=$(basename "$(dirname "$output_path")")
		output="${output#*-}"  # Strip 'cardX-' prefix
		if [[ -n "$output" ]]; then
				resolution_cmd="xrandr --output $output --mode 1920x1080 --rate 60"
				# Append only if not already present
				if ! grep -Fxq "$resolution_cmd" /usr/share/sddm/scripts/Xsetup; then
						echo "$resolution_cmd" >> /usr/share/sddm/scripts/Xsetup
				fi
		fi
fi


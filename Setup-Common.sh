#!/bin/bash

# TO DO: 
# - Account for Gentoo OpenRC (if I switch to it one day)

die() {
    # Handle exits on error
    printf "\033[1;31mError:\033[0m %s\n" "$*" >&2
    read -rp "Press Enter to exit..."
    exit 1
}

check_if_root() {
    # Check if the script is run as root
    if [ "$EUID" -ne 0 ]; then
        die "Please run the script using sudo."
    fi
}

check_if_not_root_account() {
    # Check if the script is run from the root account
    if [ "$SUDO_USER" = "" ]; then
        die "Please do not run this script from the root account. Use sudo instead."
    fi
}

get_current_username() {
    # Get the current username
    username=$SUDO_USER
}

prompt_for_autologin() {
    # Autologin Prompt
    while true; do
        read -rp "Enable autologin for $username? [y/N]: " autologin_input
        if [[ "$autologin_input" =~ ^([yY][eE][sS]?|[yY])$ ]]; then
            enable_autologin=true
            break
        elif [[ "$autologin_input" =~ ^([nN][oO]?)$ ]]; then
            enable_autologin=false
            break
        else
            echo "Invalid input. Please answer y or n."
        fi
    done
}

# NixOS doesn't use this
prompt_for_vm() {
    # VM Prompt
    while true; do
        read -rp "Is this a Virtual Machine? [y/N]: " response
        if [[ "$response" =~ ^([yY][eE][sS]?|[yY])$ ]]; then
            is_vm=true
            break
        elif [[ "$response" =~ ^([nN][oO]?)$ ]]; then
            is_vm=false
            break
        else
            echo "Invalid input. Please answer y or n."
        fi
    done
}

display_status() {
    # Display Status from Prompts
    echo "Autologin: $1"
    echo "Is VM: $2"
}

# Only Gentoo uses this
set_video_card() {
# Set VIDEO_CARDS value in package.use
  while true; do
    echo "Select your video card type:"
    echo
    echo "1) amdgpu radeonsi"
    echo "2) nvidia"
    echo "3) intel"
    echo "4) nouveau (open source)"
    echo "5) virgl (QEMU/KVM)"
    echo "6) vc4 (Raspberry Pi)"
    echo "7) d3d12 (WSL)"
    echo "8) other"
    echo
    read -p "Enter the number corresponding to your video card: " video_card_number

    case $video_card_number in
      1) video_card="amdgpu radeonsi"; break ;;
      2) video_card="nvidia"; break ;;
      3) video_card="intel"; break ;;
      4) video_card="nouveau"; break ;;
      5) video_card="virgl"; break ;;
      6) video_card="vc4"; break ;;
      7) video_card="d3d12"; break ;;
      8)
        read -p "Enter the video card type: " video_card; break ;;
      *) echo "Invalid selection, please try again." ;;
    esac
  done

  # Create or update the /etc/portage/package.use/00video-cards file
  echo "*/* VIDEO_CARDS: $video_card" > /etc/portage/package.use/00video-cards || die "Failed to update VIDEO_CARDS in /etc/portage/package.use/00video-cards."
  echo; echo "Updated VIDEO_CARDS in /etc/portage/package.use/00video-cards to $video_card based on provided input."; echo
}

# Only Gentoo/openSUSE/Slackware uses this
set_polkit_perms() {
    # Set polkit permissions for wheel group users
    cat << 'EOF' | tee /etc/polkit-1/rules.d/10-admin.rules > /dev/null || die "Failed to set polkit rules."
polkit.addAdminRule(function(action, subject) {
    return ["unix-group:wheel"];
});
EOF
}

# Only Void uses this
configure_pipewire() {
    # Remove PulseAudio-related components
    xbps-remove -y alsa-plugins-pulseaudio pulseaudio rtkit >/dev/null 2>&1
    
    # Configure PipeWire to use WirePlumber 
    mkdir -p /etc/pipewire/pipewire.conf.d || die "Failed to make PipeWire directory."
    ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/ || die "Failed to symlink WirePlumber."

    # Configure PipeWire-Pluse
    ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/ || die "Failed to symlink pipewire-pulse."

    # Configure PipeWire ALSA
    mkdir -p /etc/alsa/conf.d || die "Failed to make PipeWire ALSA directory."
    ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d || die "Failed to symlink PipeWire config."
    ln -sf /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d || die "Failed to symlink PipeWire default config."

    # Autostart PipeWire
    ln -sf /usr/share/applications/pipewire.desktop /etc/xdg/autostart || die "Failed to autostart PipeWire."
}

enable_flathub() {
    # Enable Flathub remote for Flatpak
    echo "Enabling Flathub..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || die "Failed to enable Flathub remote."
}


# NixOS/Slackware doesn't use this
preserve_old_libvirt_configs() {
    # Preserve old configurations with timestamp
    local timestamp=$(date +%s)

    cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old.$timestamp >/dev/null 2>&1
    cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old.$timestamp >/dev/null 2>&1
}

# NixOS/Slackware doesn't use this
set_libvirtd_permissions() {
    echo "Configuring libvirt..."
    # Set proper permissions in libvirtd.conf
    for line in \
      'unix_sock_group = "libvirt"' \
      'unix_sock_ro_perms = "0777"' \
      'unix_sock_rw_perms = "0770"'; do
      key=${line%% *}
      # Only add the line if it's completely missing (including commented-out lines)
      if ! grep -q -E "^$key\s*=" /etc/libvirt/libvirtd.conf; then
        # Append the line if it doesn't exist in any form
        echo "$line" | tee -a /etc/libvirt/libvirtd.conf >/dev/null 2>&1 || die "Failed to update libvirtd.conf with $line."
      fi
    done
}

# NixOS/Slackware doesn't use this
set_qemu_permissions() {
    echo "Configuring QEMU..."
    # Set proper permissions in qemu.conf
    for key in user group swtpm_user swtpm_group; do
      if ! grep -q "^$key = \"$username\"$" /etc/libvirt/qemu.conf; then
        echo "$key = \"$username\"" | tee -a /etc/libvirt/qemu.conf >/dev/null 2>&1 || die "Failed to update qemu.conf with $key = \"$username\"."
      fi
    done
}

# NixOS doesn't use this
manage_virsh_network() {
    # Only enable net-autostart if in physical machine
    local distro=${1:-}

    echo "Configuring virsh..."
    if [ "$is_vm" = false ]; then
        virsh net-autostart default >/dev/null 2>&1
        virsh net-start default >/dev/null 2>&1
    else
        virsh net-autostart default --disable >/dev/null 2>&1
        rm -f /etc/libvirt/qemu/networks/autostart/default.xml
        if virsh net-info default | grep -q "Active:.*yes"; then
            virsh net-destroy default >/dev/null 2>&1
        fi

        # Restart libvirtd based on distro
        if [ "$distro" = "void" ]; then
            sv restart libvirtd >/dev/null 2>&1
        elif [ "$distro" = "slackware" ]; then
            /etc/rc.d/rc.libvirt restart >/dev/null 2>&1
        else
            systemctl restart libvirtd >/dev/null 2>&1
        fi
    fi
}

# NixOS doesn't use this
add_user_to_groups() {
    echo "Adding User to Appropriate Groups..."
    # Add user to necessary groups
    local groups=("$@")
    for group in "${groups[@]}"; do
        usermod -aG "$group" "$username" || die "Failed to add user $username to group $group."
    done
}

# NixOS doesn't use this
backup_lightdm_config() {
    # Backup original LightDM config with timestamp
    local timestamp=$(date +%s)
    cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.old.$timestamp >/dev/null 2>&1
}

# NixOS doesn't use this
modify_lightdm_conf() {
    # Modify lightdm.conf in-place
    local distro=${1:-}

    echo "Configuring LightDM..."
    awk -v user="$username" -v autologin="$enable_autologin" -v distro="$distro" -i inplace '
    /^\[Seat:\*\]/ {a=1}
    a==1 && /^#?greeter-hide-users=/ {
        print "greeter-hide-users=false"
        next
    }
    a==1 && /^#?greeter-session=/ {
        if (distro == "arch" || distro == "slackware") {
            print "greeter-session=lightdm-slick-greeter"
            next
        }
    }
    a==1 && /^#?autologin-user=/ {
        if (autologin == "true") {
            print "autologin-user=" user
        } else {
            print "#autologin-user=" user
        }
        next
    }
    a==1 && /^#?autologin-session=/ {
        print "autologin-session=cinnamon"
        next
    }
    a==1 && /^#?user-session=/ {
        if (distro == "gentoo") {
            print "user-session=cinnamon"
            next
        }
    }
    {print}
    ' /etc/lightdm/lightdm.conf || die "Failed to modify LightDM configuration."
}

# NixOS doesn't use this
ensure_autologin_group() {
    echo "Adding User to Autologin Group..."
    # Ensure autologin group exists and add user
    groupadd -f autologin || die "Failed to create autologin group."
    gpasswd -a "$username" autologin || die "Failed to add user to autologin group."
}

# NixOS doesn't use this
set_lightdm_display_for_vm() {
    # If running in a VM, set display-setup-script in lightdm.conf
    if [ "$is_vm" = true ]; then
        # Detect connected output using sysfs (avoids X dependency)
        output_path=$(grep -l connected /sys/class/drm/*/status | head -n1) || die "Failed to detect connected display output."
        output=$(basename "$(dirname "$output_path")")
        output="${output#*-}"  # Strip 'cardX-' prefix
        if [[ -n "$output" ]]; then
            sed -i "/^\[Seat:\*\]/,/^\[.*\]/ {
                s|^#*display-setup-script=.*|display-setup-script=xrandr --output $output --mode 1920x1080 --rate 60|
            }" /etc/lightdm/lightdm.conf || die "Failed to update lightdm.conf with display-setup-script."
        fi
    fi
}

# NixOS/Slackware/Void doesn't use this
set_systemd_timeout_stop() {
    echo "Setting systemd service shutdown timeout to 15 seconds..."
    # Set timeout for stopping services during shutdown via drop in file
    mkdir -p /etc/systemd/system.conf.d || die "Failed to create directory /etc/systemd/system.conf.d."
    echo "[Manager]" | tee /etc/systemd/system.conf.d/override.conf >/dev/null 2>&1 || die "Failed to write to /etc/systemd/system.conf.d/override.conf."
    echo "DefaultTimeoutStopSec=15s" | tee -a /etc/systemd/system.conf.d/override.conf >/dev/null 2>&1 || die "Failed to append to /etc/systemd/system.conf.d/override.conf."
}

# NixOS/Slackware/Void doesn't use this
reload_systemd_daemon() {
    # Reload systemd to apply changes
    systemctl daemon-reload >/dev/null 2>&1
}

add_setup_theme_flag() {
    local distro=$1
    su - "$SUDO_USER" -c "touch $(pwd)/.$distro.done" || die "Failed to create the done flag for $distro."
}

print_reboot_message() {
    echo "Installation complete! Please reboot for the changes to take effect."
    echo "Then run Theme.sh in cinnamon-dotfiles for theming."
}

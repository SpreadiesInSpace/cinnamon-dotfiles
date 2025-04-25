#!/bin/bash

# TO DO: 
# - Remove All Verbose Copies 
# - Suppress All Functions' Outputs
# - Echo Relavent Descriptions for All Functions
# - Account for Gentoo OpenRC (if I switch to it one day)

check_if_root() {
    # Check if the script is run as root
    if [ "$EUID" -ne 0 ]; then
        echo "Please run the script using sudo."
        exit
    fi
}

check_if_not_root_account() {
    # Check if the script is run from the root account
    if [ "$SUDO_USER" = "" ]; then
        echo "Please do not run this script from the root account. Use sudo instead."
        exit
    fi
}

get_current_username() {
    # Get the current username
    username=$SUDO_USER
}

prompt_for_autologin() {
    # Autologin Prompt
    read -rp "Enable autologin for $username? [y/N]: " autologin_input
    case "$autologin_input" in
        [yY][eE][sS]|[yY])
            enable_autologin=true
            ;;
        *)
            enable_autologin=false
            ;;
    esac
}

# NixOS doesn't use this
prompt_for_vm() {
    # VM Prompt
    read -rp "Is this a Virtual Machine? [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            is_vm=true
            ;;
        *)
            is_vm=false
            ;;
    esac
}

display_status() {
  # Display Status from Prompts
  echo "Autologin: $1"
  echo "Is VM: $2"
}

enable_flathub() {
# Function to enable Flathub remote for Flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

# NixOS/Slackware doesn't use this
preserve_old_libvirt_configs() {
    # Preserve old configurations
    cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.old
    cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.old
}

# NixOS/Slackware doesn't use this
set_libvirtd_permissions() {
    # Set proper permissions in libvirtd.conf
    for line in \
      'unix_sock_group = "libvirt"' \
      'unix_sock_ro_perms = "0777"' \
      'unix_sock_rw_perms = "0770"'; do
      key=${line%% *}
      # Only add the line if it's completely missing (including commented-out lines)
      if ! grep -q -E "^$key\s*=" /etc/libvirt/libvirtd.conf; then
        # Append the line if it doesn't exist in any form
        echo "$line" | tee -a /etc/libvirt/libvirtd.conf > /dev/null
      fi
    done
}

# NixOS/Slackware doesn't use this
set_qemu_permissions() {
    # Set proper permissions in qemu.conf
    for key in user group swtpm_user swtpm_group; do
      if ! grep -q "^$key = \"$username\"$" /etc/libvirt/qemu.conf; then
        echo "$key = \"$username\"" | tee -a /etc/libvirt/qemu.conf > /dev/null
      fi
    done
}

# NixOS doesn't use this
manage_virsh_network() {
    # Only enable net-autostart if in physical machine
    local distro=${1:-}

    if [ "$is_vm" = false ]; then
        virsh net-autostart default
        virsh net-start default
    else
        virsh net-autostart default --disable
        rm -f /etc/libvirt/qemu/networks/autostart/default.xml
        if virsh net-info default | grep -q "Active:.*yes"; then
            virsh net-destroy default
        fi

        # Restart libvirtd based on distro
        if [ "$distro" = "void" ]; then
            sv restart libvirtd
        elif [ "$distro" = "slackware" ]; then
            /etc/rc.d/rc.libvirt restart
        else
            systemctl restart libvirtd
        fi
    fi
}

# NixOS doesn't use this
add_user_to_groups() {
    # Add user to necessary groups
    local groups=("$@")
    for group in "${groups[@]}"; do
        usermod -aG "$group" "$username"
    done
}


# NixOS doesn't use this
backup_lightdm_config() {
    # Backup original LightDM config
    cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.old
}

# NixOS doesn't use this
modify_lightdm_conf() {
    # Modify lightdm.conf in-place
    local distro=${1:-}

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
    ' /etc/lightdm/lightdm.conf
}

# NixOS doesn't use this
ensure_autologin_group() {
    # Ensure autologin group exists and add user
    groupadd -f autologin
    gpasswd -a "$username" autologin
}


# NixOS doesn't use this
set_lightdm_display_for_vm() {
    # If running in a VM, set display-setup-script in lightdm.conf
    if [ "$is_vm" = true ]; then
        # Detect connected output using sysfs (avoids X dependency)
        output_path=$(grep -l connected /sys/class/drm/*/status | head -n1)
        output=$(basename "$(dirname "$output_path")")
        output="${output#*-}"  # Strip 'cardX-' prefix
        if [[ -n "$output" ]]; then
            sed -i "/^\[Seat:\*\]/,/^\[.*\]/ {
                s|^#*display-setup-script=.*|display-setup-script=xrandr --output $output --mode 1920x1080 --rate 60|
            }" /etc/lightdm/lightdm.conf
        fi
    fi
}

# NixOS/Slackware/Void doesn't use this
set_systemd_timeout_stop() {
    # Set timeout for stopping services during shutdown via drop in file
    mkdir -p /etc/systemd/system.conf.d
    echo "[Manager]" | tee /etc/systemd/system.conf.d/override.conf
    echo "DefaultTimeoutStopSec=15s" | tee -a /etc/systemd/system.conf.d/override.conf
}

# NixOS/Slackware/Void doesn't use this
reload_systemd_daemon() {
    # Reload systemd to apply changes
    systemctl daemon-reload
}

add_setup_theme_flag() {
    local distro=$1
    su - "$SUDO_USER" -c "touch $(pwd)/.$distro.done"
}

print_reboot_message() {
    echo "Installation complete! Please reboot for the changes to take effect."
    echo "Then run Theme.sh in cinnamon-dotfiles for theming."
}

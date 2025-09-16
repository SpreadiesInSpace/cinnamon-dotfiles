#!/usr/bin/env bash

# Toggle Share Mount Script
# Mounts or unmounts a 9p virtio share to ~/Share

MOUNT_POINT="${HOME}/Share"
SHARE_PATH="/sharepoint"

# Check if already mounted
if mountpoint -q "$MOUNT_POINT"; then
  # Unmount the share
  if pkexec umount "$MOUNT_POINT"; then
    notify-send "Share Unmounted" \
      "Successfully unmounted $MOUNT_POINT"
    echo "Share unmounted successfully"
  else
    notify-send "Error" "Failed to unmount share"
    echo "Failed to unmount share"
    exit 1
  fi
else
  # Create mount point if it doesn't exist
  mkdir -p "$MOUNT_POINT"
  chmod 755 "$MOUNT_POINT"

  # Mount the share
  if pkexec mount -t 9p -o trans=virtio "$SHARE_PATH" "$MOUNT_POINT"; then
    notify-send "Share Mounted" \
      "Successfully mounted to $MOUNT_POINT"
    echo "Share mounted successfully to $MOUNT_POINT"
  else
    notify-send "Error" "Failed to mount share"
    echo "Failed to mount share"
    exit 1
  fi
fi
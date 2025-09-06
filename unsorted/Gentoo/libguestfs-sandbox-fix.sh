#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
	die "Please run the script as superuser."
fi

# For guestfs-tools (libguestfs currently triggers sandbox violation)
mkdir -p /etc/portage/{env,package.env} || die "Failed to make env directory."
echo 'FEATURES="-sandbox -usersandbox"' > /etc/portage/env/no-sandbox.conf \
	|| die "Failed to make no-sandbox flags config file."
echo 'app-emulation/libguestfs no-sandbox.conf' >> \
	/etc/portage/package.env/libguestfs || \
	die "Failed to add no-sandbox flags to libguestfs."
#!/bin/bash

# Prompt for BINHOST usage
read -rp "Use this system as a BINHOST? [y/N]: " use_binhost

# If binhost is enabled, use binpkg. If not, use -march=native and set CPU flags.
if [[ "$use_binhost" =~ ^[Yy]$ ]]; then
  # Set COMMON_FLAGS to "-O2 -pipe"
  sed -i 's/^COMMON_FLAGS=".*"/COMMON_FLAGS="-O2 -pipe"/' /etc/portage/make.conf
  # Add buildpkg
  sed -i 's/^FEATURES=".*"/FEATURES="buildpkg parallel-fetch parallel-install getbinpkg binpkg-request-signature"/' \
    /etc/portage/make.conf
  echo "Set make.conf for building binary packages (BINHOST)."
else
  # Set COMMON_FLAGS to "-O2 -pipe -march=native"
  sed -i 's/^COMMON_FLAGS=".*"/COMMON_FLAGS="-O2 -pipe -march=native"/' \
    /etc/portage/make.conf
  # Add getbinpkg for consuming binary packages
  sed -i 's/^FEATURES=".*"/FEATURES="parallel-fetch parallel-install getbinpkg binpkg-request-signature"/' \
    /etc/portage/make.conf
  # Set CPU flags
  emerge -1qv app-portage/cpuid2cpuflags
  echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
  echo "Set make.conf for native compilation and applied CPU-specific USE \
flags."
  # Set LINGUAS for localization
  # echo "*/* LINGUAS: en" | tee /etc/portage/package.use/00localization
fi

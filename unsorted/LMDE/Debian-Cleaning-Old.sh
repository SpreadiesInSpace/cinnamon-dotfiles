#!/bin/bash

# Debian Cleaning (Up to LMDE 6)
cleanKernel() {
  local packages
  mapfile -t packages < <(dpkg-query -W -f'${Package}\n' 'linux-*' | \
    sed -nr 's/.*-([0-9]+(\.[0-9]+){2}-[^-]+).*/\1 &/p' | \
    linux-version sort | \
    awk '($1==c){exit} {print $2}' c="$(uname -r | cut -f1,2 -d-)")

  if (( ${#packages[@]} > 0 )); then
    sudo apt-get purge "${packages[@]}" || \
      warn "Failed to remove old kernels."
  else
    echo "No old kernels to remove"
  fi
}
#!/bin/bash

# Minimal Error Handling function
die() { echo -e "\033[1;31mError:\033[0m $*" >&2; exit 1; }

# Generate the cleanup script
cat << 'EOF' > cleanup-temp.sh || die "Failed to write cleanup-temp.sh"
#!/bin/bash

cd "$HOME" || exit 1

rm -rf cinnamon-dotfiles/
rm -rf Old_Desktop_Configuration*.dconf
rm -rf .*.old
rm -rf .*.old.*

# Delete this script after running
rm -- "$0"
EOF

# Run the cleanup script
bash cleanup-temp.sh || die "Cleanup script failed"

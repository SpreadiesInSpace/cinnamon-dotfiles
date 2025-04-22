#!/bin/bash

# Generate the cleanup script
cat << 'EOF' > cleanup-temp.sh
#!/bin/bash

cd "$HOME"

rm -rf cinnamon-dotfiles/
rm -rf Old_Desktop_Configuration.dconf
rm -rf .*.old
rm -rf .*.done

# Delete this script after running
rm -- "$0"
EOF

# Run the cleanup script
bash cleanup-temp.sh


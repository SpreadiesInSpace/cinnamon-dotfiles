#!/bin/bash

# Generate the cleanup script
cat << 'EOF' > cleanup-temp.sh
#!/bin/bash

cd "$HOME"

rm -rf cinnamon-dotfiles/
rm -rf Old_Desktop_Configuration.dconf
rm -rf .*.old

# Delete this script after running
rm -- "$0"
EOF

# Make it executable
chmod +x cleanup-temp.sh

# Run the cleanup script
./cleanup-temp.sh


#!/bin/bash

# Apply ANTIALIAS to LANCZOS patch for cinnamon-settings backgrounds
# List of files to update
files=(
	"/usr/share/cinnamon/cinnamon-settings-users/cinnamon-settings-users.py"
	"/usr/share/cinnamon/cinnamon-settings/bin/imtools.py"
	"/usr/share/cinnamon/cinnamon-settings/modules/cs_backgrounds.py"
	"/usr/share/cinnamon/cinnamon-settings/modules/cs_user.py"
)
# Iterate over each file and replace 'ANTIALIAS' with 'LANCZOS'
for file in "${files[@]}"; do
	if [ -f "$file" ]; then
		sed -i 's/ANTIALIAS/LANCZOS/g' "$file"
		echo "Updated $file"
	else
		echo "File $file not found"
	fi
done
echo "cinnamon-settings backgrounds LANCZOS patch complete!"

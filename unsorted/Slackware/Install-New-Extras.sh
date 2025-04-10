#!/bin/bash

# Locale Generation (optional — only needed if en_US.UTF-8 is missing)
# localedef -i en_US -f UTF-8 en_US.UTF-8

# Set Locale (need LC_COLLATE=C so scripts don't break)
# echo 'export LANG=en_US.UTF-8' > /etc/profile.d/lang.sh
# echo "export LC_COLLATE=C" >> /etc/profile.d/lang.sh
# chmod +x /etc/profile.d/lang.sh

# Set Keymap
# echo '#!/bin/sh' > /etc/rc.d/rc.keymap
# echo 'loadkeys us' >> /etc/rc.d/rc.keymap
# chmod +x /etc/rc.d/rc.keymap

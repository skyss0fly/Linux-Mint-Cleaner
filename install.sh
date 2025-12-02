#!/bin/bash

set -e

echo "Installing Linux Mint Cleaner..."

# Install main script
sudo mkdir -p /usr/local/bin
sudo cp src/mint-cleaner.sh /usr/local/bin/mint-cleaner
sudo chmod +x /usr/local/bin/mint-cleaner

# Install desktop file
sudo mkdir -p /usr/local/share/applications
sudo cp desktop/mint-cleaner.desktop /usr/local/share/applications/
sudo chmod 644 /usr/local/share/applications/mint-cleaner.desktop

# Install icon
if [ -f icons/system-cleaner.png ]; then
    sudo mkdir -p /usr/local/share/icons/hicolor/48x48/apps
    sudo cp icons/system-cleaner.png /usr/local/share/icons/hicolor/48x48/apps/mint-cleaner.png
fi

echo "Updating icon cache..."
sudo update-icon-caches /usr/local/share/icons/hicolor || true

echo "Installation complete!"
echo "You can now launch 'Linux Mint Cleaner' from the Mint menu."


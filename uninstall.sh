#!/bin/bash
set -euo pipefail

# ------------------------
# Linux Mint Cleaner Uninstaller
# ------------------------

# Paths installed by install.sh
BIN_DEST="/usr/local/bin/mint-cleaner"
DESKTOP_DEST="/usr/share/applications/mint-cleaner.desktop"
ICON_DEST="/usr/share/icons/hicolor/scalable/apps/linux-mint-cleaner.svg"

echo "Uninstalling Linux Mint Cleaner..."

# ------------------------
# 1️⃣ Remove script
# ------------------------
if [ -f "$BIN_DEST" ]; then
    sudo rm -f "$BIN_DEST"
    echo "✅ Removed script: $BIN_DEST"
else
    echo "⚠ Script not found, skipping: $BIN_DEST"
fi

# ------------------------
# 2️⃣ Remove desktop launcher
# ------------------------
if [ -f "$DESKTOP_DEST" ]; then
    sudo rm -f "$DESKTOP_DEST"
    echo "✅ Removed desktop launcher: $DESKTOP_DEST"
else
    echo "⚠ Desktop launcher not found, skipping: $DESKTOP_DEST"
fi

# ------------------------
# 3️⃣ Remove icon
# ------------------------
if [ -f "$ICON_DEST" ]; then
    sudo rm -f "$ICON_DEST"
    echo "✅ Removed icon: $ICON_DEST"
else
    echo "⚠ Icon not found, skipping: $ICON_DEST"
fi

# ------------------------
# 4️⃣ Update caches
# ------------------------
echo "Updating icon cache..."
sudo gtk-update-icon-cache /usr/share/icons/hicolor || true

echo "Updating desktop database..."
sudo update-desktop-database /usr/share/applications || true

# ------------------------
# 5️⃣ Finished
# ------------------------
echo "🎉 Linux Mint Cleaner has been uninstalled!"
echo "You may want to restart Cinnamon to refresh the menu."

# Optional: restart Cinnamon menu immediately
if pidof cinnamon >/dev/null; then
    cinnamon --replace & disown
fi


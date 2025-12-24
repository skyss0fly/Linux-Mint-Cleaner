#!/bin/bash
set -euo pipefail

# ------------------------
# Linux Mint Cleaner Installer
# ------------------------

# Project folder paths (relative to installer)
SCRIPT_SRC="./usr/local/bin/mint-cleaner.sh"
DESKTOP_SRC="./usr/share/applications/mint-cleaner.desktop"
ICON_SRC="./usr/share/icons/hicolor/scalable/apps/linux-mint-cleaner.svg"

# Destination paths
BIN_DEST="/usr/local/bin/mint-cleaner"
DESKTOP_DEST="/usr/share/applications/mint-cleaner.desktop"
ICON_DEST="/usr/share/icons/hicolor/scalable/apps/system-cleaner.svg"


echo "Installing Linux Mint Cleaner..."

# ------------------------
# 1️⃣ Copy main script
# ------------------------
if [ ! -f "$SCRIPT_SRC" ]; then
    echo "Error: $SCRIPT_SRC not found. Make sure you run this from project root."
    exit 1
fi
sudo cp "$SCRIPT_SRC" "$BIN_DEST"
sudo chmod +x "$BIN_DEST"
echo "✅ Script installed to $BIN_DEST"

# ------------------------
# 2️⃣ Copy desktop launcher
# ------------------------
if [ ! -f "$DESKTOP_SRC" ]; then
    echo "Error: $DESKTOP_SRC not found."
    exit 1
fi

# Fix the desktop file: ensure Exec points to /usr/local/bin and absolute icon path
TMP_DESKTOP=$(mktemp)
awk -v exec="$BIN_DEST" -v icon="$ICON_DEST" '
    /^Exec=/ {$0="Exec=" exec}
    /^Icon=/ {$0="Icon=" icon}
    {print}
' "$DESKTOP_SRC" > "$TMP_DESKTOP"

sudo cp "$TMP_DESKTOP" "$DESKTOP_DEST"
sudo chmod 644 "$DESKTOP_DEST"
rm "$TMP_DESKTOP"
echo "✅ Desktop launcher installed to $DESKTOP_DEST"

# ------------------------
# 3️⃣ Copy icon
# ------------------------
if [ -f "$ICON_SRC" ]; then
    sudo mkdir -p "$(dirname "$ICON_DEST")"
    sudo cp "$ICON_SRC" "$ICON_DEST"
    echo "✅ Icon installed to $ICON_DEST"
else
    echo "⚠ Icon not found. Skipping."
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
echo "🎉 Installation complete!"
echo "You can now launch 'Linux Mint Cleaner' from the Mint menu or by running:"
echo "mint-cleaner"



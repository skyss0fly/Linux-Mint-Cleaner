#!/bin/bash
# ================================================================
#  Linux Mint Cleaner GUI - Advanced Version
#  Modes: Light / Full / Timeshift Only
#  Logging, Zenity GUI, systemd-ready
# ================================================================

set -euo pipefail

# -------------------------------
# Log setup
# -------------------------------
LOGFILE="/usr/share/mint-cleaner.log"
DIR="$(dirname "$LOGFILE")"

# Ensure directory exists and log file is writable
sudo mkdir -p "$DIR"
sudo touch "$LOGFILE"
sudo chmod 644 "$LOGFILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

# -------------------------------
# Mode selector (GUI)
# -------------------------------
MODE=$(zenity --list \
    --title="Linux Mint Cleaner V0.1.6-Dev2" \
    --text="Choose a cleanup mode:" \
    --column="Mode" --column="Description" \
    "Light" "Safe cleaning: caches, thumbnails, trash" \
    "Full" "Deep cleaning + Flatpak + Timeshift (keeps newest snapshot)" \
    "Timeshift Only" "Delete all old snapshots, keep newest" \
    --width=400 --height=280)

[[ -z "$MODE" ]] && exit 0

# -------------------------------
# Cleanup task
# -------------------------------
cleanup_task() {
(
P=0

progress() {
    echo "$P"
    echo "# $1"
    log "$1"
    P=$((P+7))
}

# -------------------------------
# 1. APT cache (Full only)
# -------------------------------
if [[ "$MODE" == "Full" ]]; then
    progress "Cleaning APT cache..."
    sudo apt-get clean
    sudo rm -rf /var/cache/apt/archives/*
fi

progress "Cleaning system cache..."
sudo rm -rf /var/cache/* || true

# -------------------------------
# 2. User cache (excluding browsers)
# -------------------------------
progress "Cleaning user cache..."
BROWSER_DIRS=("google-chrome" "chromium" "mozilla" "brave" "vivaldi")

shopt -s nullglob
for dir in ~/.cache/*; do
    skip=false
    for b in "${BROWSER_DIRS[@]}"; do
        [[ "$dir" == *"/$b" ]] && skip=true
    done
    if [ "$skip" = false ]; then
        rm -rf "$dir" || true
    fi
done
shopt -u nullglob

# -------------------------------
# 3. Thumbnails
# -------------------------------
progress "Cleaning thumbnail cache..."
rm -rf ~/.cache/thumbnails/* || true

# -------------------------------
# 4. Trash
# -------------------------------
progress "Emptying Trash..."
rm -rf ~/.local/share/Trash/files/* ~/.local/share/Trash/info/* || true

# -------------------------------
# 5. Flatpak cache (Full only)
# -------------------------------
if [[ "$MODE" == "Full" ]]; then
    progress "Cleaning Flatpak leftover data..."
    sudo flatpak uninstall --unused -y || true
    rm -rf ~/.var/app/*/cache/* || true
fi

# -------------------------------
# 6. Timeshift snapshots (Full / Timeshift Only)
# -------------------------------
if [[ "$MODE" == "Full" || "$MODE" == "Timeshift Only" ]]; then
    progress "Checking Timeshift snapshots..."
    SNAPSHOTS=$(sudo timeshift --list | awk '/----/ {found=1; next} found && NF>=3 {print $3}')

    if [[ -z "$SNAPSHOTS" ]]; then
        progress "No Timeshift snapshots found. Skipping."
    else
        LATEST=$(echo "$SNAPSHOTS" | tail -n 1)

        if zenity --question --title="Timeshift Cleanup" \
            --text="Newest Timeshift snapshot:\n$LATEST\n\nDelete all older snapshots?"; then
            for snap in $SNAPSHOTS; do
                if [[ "$snap" != "$LATEST" ]]; then
                    progress "Deleting old Timeshift snapshot: $snap"
                    sudo timeshift --delete --snapshot "$snap"
                else
                    progress "Keeping newest snapshot: $snap"
                fi
            done
        else
            progress "Skipped Timeshift cleanup."
        fi
    fi
fi

progress "Done!"
echo "100"

) | zenity --progress \
    --title="Linux Mint Cleaner V0.1.6-Dev2" \
    --text="Starting cleanup..." \
    --percentage=0 \
    --auto-close \
    --width=360
}

# -------------------------------
# Run cleanup
# -------------------------------
cleanup_task

# -------------------------------
# Completion message
# -------------------------------
zenity --info \
    --title="Cleanup Complete" \
    --text="Cleanup completed successfully!\n\nLog saved to:\n$LOGFILE"

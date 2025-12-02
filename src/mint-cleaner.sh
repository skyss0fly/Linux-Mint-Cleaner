#!/bin/bash

# ================================================================
#  Linux Mint Cleaner GUI - Advanced Version
#  Modes: Light / Full / Timeshift Only
#  Logging, Zenity GUI, systemd-ready
# ================================================================

set -euo pipefail

# -------------------------------
# Logging setup in app folder
# -------------------------------
APP_DIR="$(dirname "$(realpath "$0")")"   # folder where the script resides
LOGFILE="$APP_DIR/mint-cleaner.log"

# Ensure log file exists
touch "$LOGFILE"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

log "Linux Mint Cleaner started."

# -------------------------------
# Mode selector
# -------------------------------
MODE=$(zenity --list \
    --title="Linux Mint Cleaner V0.1.6" \
    --text="Choose a cleanup mode:" \
    --column="Mode" --column="Description" \
    "Light" "Safe cleaning: caches, thumbnails, trash" \
    "Full" "Deep cleaning + Flatpak + Timeshift (keeps newest snapshot)" \
    "Timeshift Only" "Delete all old snapshots, keep newest" \
    --width=400 --height=280)

[[ -z "$MODE" ]] && exit 0

# ================================
# GUI progress wrapper
# ================================
cleanup_task() {
(
P=0

progress() {
    echo "$P"
    echo "# $1"
    log "$1"
    P=$((P+7))
}

# ---------------------------
# 1. APT cache (Full only)
# ---------------------------
if [[ "$MODE" == "Full" ]]; then
    progress "Cleaning APT cache..."
    sudo apt-get clean &>/dev/null
    sudo rm -rf /var/cache/apt/archives/* &>/dev/null
fi

progress "Cleaning system cache..."
sudo rm -rf /var/cache/* &>/dev/null

# ---------------------------
# 2. User cache (browser safe)
# ---------------------------
progress "Cleaning user cache (excluding browsers)..."
BROWSER_DIRS=("google-chrome" "chromium" "mozilla" "brave" "vivaldi")

for dir in ~/.cache/*; do
    skip=false
    for b in "${BROWSER_DIRS[@]}"; do
        [[ "$dir" == *"/$b" ]] && skip=true
    done
    if ! $skip; then
        rm -rf "$dir" &>/dev/null
    fi
done

# ---------------------------
# 3. Thumbnails
# ---------------------------
progress "Cleaning thumbnail cache..."
rm -rf ~/.cache/thumbnails/* &>/dev/null

# ---------------------------
# 4. Trash
# ---------------------------
progress "Emptying Trash..."
rm -rf ~/.local/share/Trash/files/* &>/dev/null
rm -rf ~/.local/share/Trash/info/* &>/dev/null

# ---------------------------
# 5. Flatpak cache (Full only)
# ---------------------------
if [[ "$MODE" == "Full" ]]; then
    progress "Cleaning Flatpak leftover data..."
    flatpak uninstall --unused -y &>/dev/null
    rm -rf ~/.var/app/*/cache/* &>/dev/null || true
fi

# ---------------------------
# 6. Timeshift snapshots (Full or Timeshift Only)
# ---------------------------
if [[ "$MODE" == "Full" || "$MODE" == "Timeshift Only" ]]; then

progress "Checking Timeshift snapshots..."

SNAPSHOTS=$(sudo timeshift --list | awk '
    /----/ {found=1; next} 
    found && NF>=3 {print $3}
')

if [[ -z "$SNAPSHOTS" ]]; then
    progress "No Timeshift snapshots found. Skipping."
else
    LATEST=$(echo "$SNAPSHOTS" | tail -n 1)

    zenity --question \
        --title="Timeshift Cleanup" \
        --text="Newest Timeshift snapshot:\n$LATEST\n\nDelete all older snapshots?" \
        || { P=99; progress "Skipped Timeshift cleanup."; }

    for snap in $SNAPSHOTS; do
        if [[ "$snap" != "$LATEST" ]]; then
            progress "Deleting old Timeshift snapshot: $snap"
            sudo timeshift --delete --snapshot "$snap" &>/dev/null
        else
            progress "Keeping newest snapshot: $snap"
        fi
    done
fi

fi # Timeshift

progress "Done!"
echo "100"
) | zenity --progress \
    --title="Linux Mint Cleaner V0.1.6" \
    --text="Starting cleanup..." \
    --percentage=0 \
    --auto-close \
    --width=360

}

cleanup_task

zenity --info \
    --title="Cleanup Complete" \
    --text="Cleanup completed successfully!\n\nLog saved to:\n$LOGFILE"

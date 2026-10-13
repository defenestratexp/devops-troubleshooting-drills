#!/usr/bin/env bash
# Builds a small loopback filesystem, fills it, then deletes the file while a
# process still holds it open - the classic phantom-disk-usage situation.
set -e
cd "$(dirname "$0")"
MNT=/tmp/practice-disk
IMG=/tmp/practice-disk.img
sudo umount "$MNT" 2>/dev/null || true
rm -f "$IMG"; sudo rm -rf "$MNT"
truncate -s 64M "$IMG"
mkfs.ext4 -q "$IMG"
sudo mkdir -p "$MNT"
sudo mount -o loop "$IMG" "$MNT"
sudo chmod 777 "$MNT"
dd if=/dev/zero of="$MNT/app.log" bs=1M count=48 status=none
# Hold it open, then delete it. Space stays allocated until the fd closes.
setsid bash -c "exec 9<\"$MNT/app.log\"; sleep 3600" >/dev/null 2>&1 &
sleep 1
rm -f "$MNT/app.log"
echo "Situation created. Look at $MNT"
echo "  df -h $MNT   vs   du -sh $MNT"

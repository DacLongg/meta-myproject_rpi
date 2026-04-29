#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_DIR/output}"
DEFAULT_DEVICE="${DEFAULT_DEVICE:-/dev/sda}"

die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

device_basename() {
  basename "$1"
}

root_disk_name() {
  local root_source root_pkname

  root_source="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
  [[ -n "$root_source" ]] || return 0

  root_pkname="$(lsblk -no PKNAME "$root_source" 2>/dev/null || true)"
  if [[ -n "$root_pkname" ]]; then
    printf '%s\n' "$root_pkname"
  else
    device_basename "$root_source"
  fi
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  die "Must be root: sudo ./flash_rpi_sd.sh"
fi

if [[ ! -d "$OUTPUT_DIR" ]]; then
  die "Cannot find output directory: $OUTPUT_DIR. Please run ./build_rpi_image.sh first."
fi

shopt -s nullglob
wic_files=("$OUTPUT_DIR"/*.wic)
shopt -u nullglob

if [[ ${#wic_files[@]} -eq 0 ]]; then
  die "Cannot find .wic file in $OUTPUT_DIR. Please run ./build_rpi_image.sh first."
fi

wic_file="$(ls -t "${wic_files[@]}" | head -n 1)"

printf 'Image will be flashed:\n  %s\n\n' "$wic_file"
printf 'Block devices currently available:\n'
lsblk -o NAME,TYPE,SIZE,MODEL,TRAN,MOUNTPOINTS
printf '\n'

read -r -p "Enter SD device to flash [default: $DEFAULT_DEVICE]: " device
device="${device:-$DEFAULT_DEVICE}"

[[ -b "$device" ]] || die "Invalid block device: $device"

device_type="$(lsblk -no TYPE "$device" 2>/dev/null || true)"
[[ "$device_type" == "disk" ]] || die "$device is not a whole-disk device. Please choose a device in the format /dev/sdX or /dev/mmcblkX, not a partition."

root_disk="$(root_disk_name)"
if [[ -n "$root_disk" && "$(device_basename "$device")" == "$root_disk" ]]; then
  die "$device appears to be the disk running the current operating system. Stopping to avoid accidental overwriting."
fi

printf '\nWARNING: All data on %s will be erased.\n' "$device"
read -r -p 'Type YES to continue: ' confirm

if [[ "$confirm" != "YES" ]]; then
  die "Operation cancelled."
fi

printf 'Unmount partitions of %s...\n' "$device"
umount "${device}"?* 2>/dev/null || true
umount "${device}"p?* 2>/dev/null || true

printf 'Flash image...\n'
dd if="$wic_file" of="$device" bs=4M status=progress conv=fsync
sync

printf '\nFlash done. You can now remove the SD card and boot Raspberry Pi.\n'

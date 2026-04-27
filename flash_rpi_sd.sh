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
  die "Hãy chạy bằng root: sudo ./flash_rpi_sd.sh"
fi

if [[ ! -d "$OUTPUT_DIR" ]]; then
  die "Không tìm thấy output directory: $OUTPUT_DIR. Hãy chạy ./build_rpi_image.sh trước."
fi

shopt -s nullglob
wic_files=("$OUTPUT_DIR"/*.wic)
shopt -u nullglob

if [[ ${#wic_files[@]} -eq 0 ]]; then
  die "Không tìm thấy file .wic trong $OUTPUT_DIR. Hãy chạy ./build_rpi_image.sh trước."
fi

wic_file="$(ls -t "${wic_files[@]}" | head -n 1)"

printf 'Image sẽ flash:\n  %s\n\n' "$wic_file"
printf 'Block devices hiện có:\n'
lsblk -o NAME,TYPE,SIZE,MODEL,TRAN,MOUNTPOINTS
printf '\n'

read -r -p "Nhập SD device để flash [default: $DEFAULT_DEVICE]: " device
device="${device:-$DEFAULT_DEVICE}"

[[ -b "$device" ]] || die "Block device không hợp lệ: $device"

device_type="$(lsblk -no TYPE "$device" 2>/dev/null || true)"
[[ "$device_type" == "disk" ]] || die "$device không phải whole-disk device. Hãy chọn dạng /dev/sdX hoặc /dev/mmcblkX, không chọn partition."

root_disk="$(root_disk_name)"
if [[ -n "$root_disk" && "$(device_basename "$device")" == "$root_disk" ]]; then
  die "$device có vẻ là ổ đang chạy hệ điều hành hiện tại. Dừng để tránh ghi nhầm."
fi

printf '\nCẢNH BÁO: toàn bộ dữ liệu trên %s sẽ bị xóa.\n' "$device"
read -r -p 'Gõ YES để tiếp tục: ' confirm

if [[ "$confirm" != "YES" ]]; then
  die "Đã hủy."
fi

printf 'Unmount partitions của %s...\n' "$device"
umount "${device}"?* 2>/dev/null || true
umount "${device}"p?* 2>/dev/null || true

printf 'Flash image...\n'
dd if="$wic_file" of="$device" bs=4M status=progress conv=fsync
sync

printf '\nFlash xong. Có thể tháo SD card và boot Raspberry Pi.\n'

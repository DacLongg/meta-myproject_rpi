#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME="meta-myproject_rpi"
IMAGE_NAME="${IMAGE_NAME:-myproject-rpi-image}"
MACHINE="${MACHINE:-darkdragon-rpi3}"
YOCTO_ROOT="${YOCTO_ROOT:-$HOME/yocto}"
BUILD_DIR_NAME="${BUILD_DIR_NAME:-build-rpi}"

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/lib/kas.sh"
DEPLOY_DIR="$BUILD_DIR/tmp/deploy/images/$MACHINE"
OUTPUT_DIR="$PROJECT_DIR/output"

info() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

require_project_root
require_kas
require_kas_manifest

override_manifest="$(make_kas_temp_file)"
trap 'rm -f "$override_manifest"' EXIT

cat >"$override_manifest" <<EOF
header:
  version: 11
machine: $MACHINE
target:
  - $IMAGE_NAME
EOF

info "Build image: $IMAGE_NAME for $MACHINE"
kas_in_project build "$KAS_MANIFEST_REL:${override_manifest#$PROJECT_DIR/}"

info "Find latest image in $DEPLOY_DIR"
shopt -s nullglob
images=("$DEPLOY_DIR"/"$IMAGE_NAME"-"$MACHINE"-*.rootfs.wic.bz2)
if [[ ${#images[@]} -eq 0 ]]; then
  images=("$DEPLOY_DIR"/"$IMAGE_NAME"-"$MACHINE".rootfs.wic.bz2)
fi
shopt -u nullglob

if [[ ${#images[@]} -eq 0 ]]; then
  die "Cannot find .wic.bz2 file in $DEPLOY_DIR"
fi

latest_image="$(ls -t "${images[@]}" | head -n 1)"
info "Image found: $latest_image"

info "Copy output into $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

output_bz2="$OUTPUT_DIR/$(basename "$latest_image")"
output_wic="${output_bz2%.bz2}"

rm -f "$output_bz2" "$output_wic"
cp "$latest_image" "$output_bz2"

info "extract .wic.bz2 -> .wic"
bunzip2 -f "$output_bz2"

info "Build done. Output:"
ls -lh "$OUTPUT_DIR"

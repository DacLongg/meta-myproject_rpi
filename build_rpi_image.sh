#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME="meta-myproject_rpi"
IMAGE_NAME="${IMAGE_NAME:-myproject-rpi-image}"
MACHINE="${MACHINE:-raspberrypi3}"
YOCTO_ROOT="${YOCTO_ROOT:-$HOME/yocto}"
BUILD_DIR_NAME="${BUILD_DIR_NAME:-build-rpi}"

PROJECT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BUILD_DIR="$YOCTO_ROOT/$BUILD_DIR_NAME"
ENV_SCRIPT="$YOCTO_ROOT/setup-yocto-env.sh"
INIT_SCRIPT="$YOCTO_ROOT/poky/oe-init-build-env"
DEPLOY_DIR="$BUILD_DIR/tmp/deploy/images/$MACHINE"
OUTPUT_DIR="$PROJECT_DIR/output"

info() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

if [[ "$(basename "$PROJECT_DIR")" != "$PROJECT_NAME" ]]; then
  die "Script must be located in the project directory $PROJECT_NAME, currently in $PROJECT_DIR"
fi

if [[ ! -d "$BUILD_DIR/conf" ]]; then
  die "Cannot find build environment: $BUILD_DIR. Please run ./setup-yocto-build.sh first."
fi

if [[ -f "$ENV_SCRIPT" ]]; then
  info "Source Yocto env: $ENV_SCRIPT"
  set +u
  # shellcheck disable=SC1090
  source "$ENV_SCRIPT" >/dev/null
  set -u
elif [[ -f "$INIT_SCRIPT" ]]; then
  info "Source Yocto env: $INIT_SCRIPT $BUILD_DIR"
  set +u
  # shellcheck disable=SC1090
  source "$INIT_SCRIPT" "$BUILD_DIR" >/dev/null
  set -u
else
  die "Cannot find Yocto env script. Please run ./setup-yocto-build.sh first."
fi

info "Build image: $IMAGE_NAME for $MACHINE"
cd "$BUILD_DIR"
bitbake "$IMAGE_NAME"

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

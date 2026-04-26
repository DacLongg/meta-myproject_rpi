#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME="meta-myproject_rpi"
IMAGE_NAME="${IMAGE_NAME:-core-image-minimal}"
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
  die "Script phải nằm trong thư mục project $PROJECT_NAME, hiện tại là $PROJECT_DIR"
fi

if [[ ! -d "$BUILD_DIR/conf" ]]; then
  die "Chưa có build environment: $BUILD_DIR. Hãy chạy ./setup-yocto-build.sh trước."
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
  die "Không tìm thấy Yocto env script. Hãy chạy ./setup-yocto-build.sh trước."
fi

info "Build image: $IMAGE_NAME cho $MACHINE"
cd "$BUILD_DIR"
bitbake "$IMAGE_NAME"

info "Tìm image mới nhất trong $DEPLOY_DIR"
shopt -s nullglob
images=("$DEPLOY_DIR"/"$IMAGE_NAME"-"$MACHINE"-*.rootfs.wic.bz2)
if [[ ${#images[@]} -eq 0 ]]; then
  images=("$DEPLOY_DIR"/"$IMAGE_NAME"-"$MACHINE".rootfs.wic.bz2)
fi
shopt -u nullglob

if [[ ${#images[@]} -eq 0 ]]; then
  die "Không tìm thấy file .wic.bz2 trong $DEPLOY_DIR"
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

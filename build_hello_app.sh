#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME="meta-myproject_rpi"
APP_NAME="${APP_NAME:-hello}"
YOCTO_ROOT="${YOCTO_ROOT:-$HOME/yocto}"
BUILD_DIR_NAME="${BUILD_DIR_NAME:-build-rpi}"

PROJECT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BUILD_DIR="$YOCTO_ROOT/$BUILD_DIR_NAME"
ENV_SCRIPT="$YOCTO_ROOT/setup-yocto-env.sh"
INIT_SCRIPT="$YOCTO_ROOT/poky/oe-init-build-env"
PACKAGE_OUTPUT_DIR="$PROJECT_DIR/output/packages/$APP_NAME"
BINARY_OUTPUT_DIR="$PROJECT_DIR/output/binaries/$APP_NAME"

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

info "Build app recipe: $APP_NAME"
cd "$BUILD_DIR"
bitbake "$APP_NAME"

info "Copy package output into $PACKAGE_OUTPUT_DIR"
mkdir -p "$PACKAGE_OUTPUT_DIR"

mapfile -t packages < <(
  find "$BUILD_DIR/tmp/deploy" -type f \
    \( -name "$APP_NAME-*.rpm" -o -name "$APP_NAME-*.ipk" -o -name "${APP_NAME}_*.deb" \) \
    -print
)

if [[ ${#packages[@]} -eq 0 ]]; then
  die "Không tìm thấy package output cho $APP_NAME trong $BUILD_DIR/tmp/deploy"
fi

cp -f "${packages[@]}" "$PACKAGE_OUTPUT_DIR/"

info "Copy executable output into $BINARY_OUTPUT_DIR"
mkdir -p "$BINARY_OUTPUT_DIR"

mapfile -t binaries < <(
  find "$BUILD_DIR/tmp/work" -type f \
    -path "*/$APP_NAME/*/image/usr/bin/$APP_NAME" \
    -perm -111 \
    -print
)

if [[ ${#binaries[@]} -eq 0 ]]; then
  die "Không tìm thấy file chạy trực tiếp cho $APP_NAME trong $BUILD_DIR/tmp/work"
fi

latest_binary="$(ls -t "${binaries[@]}" | head -n 1)"
cp -f "$latest_binary" "$BINARY_OUTPUT_DIR/$APP_NAME"

info "Build done: $APP_NAME"
ls -lh "$PACKAGE_OUTPUT_DIR"
ls -lh "$BINARY_OUTPUT_DIR"

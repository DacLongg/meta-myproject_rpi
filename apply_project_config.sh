#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME="meta-myproject_rpi"
YOCTO_ROOT="${YOCTO_ROOT:-$HOME/yocto}"
BUILD_DIR_NAME="${BUILD_DIR_NAME:-build-rpi}"

PROJECT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BUILD_DIR="$YOCTO_ROOT/$BUILD_DIR_NAME"
PROJECT_BUILD_CONF_DIR="$PROJECT_DIR/conf/build"

info() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

if [[ "$(basename "$PROJECT_DIR")" != "$PROJECT_NAME" ]]; then
  die "Script phải nằm trong thư mục project $PROJECT_NAME, hiện tại là $PROJECT_DIR"
fi

if [[ ! -d "$BUILD_DIR/conf" ]]; then
  die "Chưa có build environment: $BUILD_DIR. Hãy chạy ./setup-yocto-build.sh trước."
fi

apply_bblayers_conf() {
  local template="$PROJECT_BUILD_CONF_DIR/bblayers.conf.in"
  local bblayers="$BUILD_DIR/conf/bblayers.conf"

  [[ -f "$template" ]] || die "Không tìm thấy template $template"
  [[ -f "$bblayers" ]] || die "Không tìm thấy $bblayers"

  info "Render bblayers.conf từ template project"
  sed \
    -e "s|@YOCTO_ROOT@|$YOCTO_ROOT|g" \
    -e "s|@PROJECT_NAME@|$PROJECT_NAME|g" \
    "$template" >"$bblayers"
}

apply_local_conf() {
  local template="$PROJECT_BUILD_CONF_DIR/local.conf.append"
  local local_conf="$BUILD_DIR/conf/local.conf"
  local tmp_conf

  [[ -f "$template" ]] || die "Không tìm thấy template $template"
  [[ -f "$local_conf" ]] || die "Không tìm thấy $local_conf"

  info "Áp dụng block cấu hình project vào local.conf"
  tmp_conf="$(mktemp)"
  awk '
    $0 == "# BEGIN meta-myproject_rpi project config" { skip = 1; next }
    $0 == "# END meta-myproject_rpi project config" { skip = 0; next }
    skip != 1 { print }
  ' "$local_conf" >"$tmp_conf"
  {
    printf '\n# BEGIN meta-myproject_rpi project config\n'
    cat "$template"
    printf '# END meta-myproject_rpi project config\n'
  } >>"$tmp_conf"
  mv "$tmp_conf" "$local_conf"
}

apply_bblayers_conf
apply_local_conf
info "Đã áp dụng cấu hình project cho $BUILD_DIR"

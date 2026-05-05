#!/usr/bin/env bash

PROJECT_NAME="${PROJECT_NAME:-meta-myproject_rpi}"
YOCTO_ROOT="${YOCTO_ROOT:-$HOME/yocto}"
BUILD_DIR_NAME="${BUILD_DIR_NAME:-build-rpi}"

KAS_LIB_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_DIR="$(cd -P "$KAS_LIB_DIR/../.." >/dev/null 2>&1 && pwd)"
BUILD_DIR="${KAS_BUILD_DIR:-$YOCTO_ROOT/$BUILD_DIR_NAME}"
KAS_MANIFEST_REL="${KAS_MANIFEST_REL:-manifests/kas.yml}"
KAS_MANIFEST="$PROJECT_DIR/$KAS_MANIFEST_REL"
KAS_BIN="${KAS_BIN:-kas}"
KAS_VENV_DIR="${KAS_VENV_DIR:-$YOCTO_ROOT/.venvs/kas}"
KAS_TMP_DIR="${KAS_TMP_DIR:-$PROJECT_DIR/.kas-tmp}"

if [[ -x "$KAS_VENV_DIR/bin/kas" ]]; then
  KAS_BIN="$KAS_VENV_DIR/bin/kas"
fi

export PATH="$HOME/.local/bin:$PATH"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_project_root() {
  if [[ "$(basename "$PROJECT_DIR")" != "$PROJECT_NAME" ]]; then
    die "Script must be located in the project directory $PROJECT_NAME, currently in $PROJECT_DIR"
  fi
}

require_kas_manifest() {
  [[ -f "$KAS_MANIFEST" ]] || die "Cannot find kas manifest: $KAS_MANIFEST"
}

require_kas() {
  if ! command_exists "$KAS_BIN"; then
    die "Cannot find kas in PATH. Please run ./scripts/setup-yocto-build.sh first or install kas manually."
  fi
}

kas_in_project() {
  (
    cd "$PROJECT_DIR"
    env KAS_WORK_DIR="$YOCTO_ROOT" KAS_BUILD_DIR="$BUILD_DIR" "$KAS_BIN" "$@"
  )
}

make_kas_temp_file() {
  mkdir -p "$KAS_TMP_DIR"
  mktemp "$KAS_TMP_DIR/override-XXXXXX.yml"
}

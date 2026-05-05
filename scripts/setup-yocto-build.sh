#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME="meta-myproject_rpi"
YOCTO_ROOT="${YOCTO_ROOT:-$HOME/yocto}"
BUILD_DIR_NAME="${BUILD_DIR_NAME:-build-rpi}"

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SOURCE_PROJECT_DIR="$(cd -P "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
PROJECT_DIR="$YOCTO_ROOT/$PROJECT_NAME"
BUILD_DIR="$YOCTO_ROOT/$BUILD_DIR_NAME"
KAS_MANIFEST_REL="manifests/kas.yml"
KAS_MANIFEST="$PROJECT_DIR/$KAS_MANIFEST_REL"
KAS_BIN="${KAS_BIN:-kas}"
KAS_VENV_DIR="${KAS_VENV_DIR:-$YOCTO_ROOT/.venvs/kas}"

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

run_with_sudo() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

install_dependencies() {
  if command_exists apt-get; then
    local apt_packages=(
      gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat cpio
      python3 python3-pip python3-pexpect python3-git python3-jinja2 python3-subunit
      python3-venv
      xz-utils debianutils iputils-ping libsdl1.2-dev xterm zstd liblz4-tool
      file locales bc
    )
    info "Update package build Yocto by apt"
    run_with_sudo apt-get update
    run_with_sudo apt-get install -y "${apt_packages[@]}"
  elif command_exists dnf; then
    local dnf_packages=(
      gawk make wget tar bzip2 gzip python3 unzip perl patch diffutils diffstat
      git cpp gcc gcc-c++ glibc-devel texinfo chrpath ccache perl-Data-Dumper
      perl-Text-ParseWords perl-Thread-Queue perl-bignum socat python3-pexpect
      findutils which file cpio python3-pip python3-virtualenv xz zstd lz4 bc
    )
    info "Update package build Yocto by dnf"
    run_with_sudo dnf install -y "${dnf_packages[@]}"
  elif command_exists zypper; then
    local zypper_packages=(
      python3 gcc gcc-c++ git chrpath make wget python3-xml diffstat makeinfo
      python3-curses patch socat python3-pexpect python3-virtualenv xz which tar gzip bzip2 unzip
      cpio file zstd lz4 bc
    )
    info "Update package build Yocto by zypper"
    run_with_sudo zypper install -y "${zypper_packages[@]}"
  elif command_exists pacman; then
    local pacman_packages=(
      base-devel git diffstat unzip texinfo chrpath socat cpio python python-pip
      python-pexpect wget xz zstd lz4 file bc
    )
    info "Update package build Yocto by pacman"
    run_with_sudo pacman -Sy --needed --noconfirm "${pacman_packages[@]}"
  else
    warn "No detected package manager."
    warn "Please install Yocto dependencies manually: git, gcc/g++, make, python3, gawk, wget, diffstat, unzip, texinfo, chrpath, socat, cpio, xz, zstd, lz4, file, bc."
  fi
}

check_dependencies() {
  local tools=(
    awk wget git diffstat unzip make gcc chrpath socat cpio python3 xz file
  )
  local missing=()

  info "Checking Yocto build dependencies"
  for tool in "${tools[@]}"; do
    if ! command_exists "$tool"; then
      missing+=("$tool")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Missing tools: ${missing[*]}"
    install_dependencies
  else
    info "Basic build tools are available"
  fi
}

install_kas() {
  info "Installing kas into virtualenv: $KAS_VENV_DIR"
  mkdir -p "$(dirname "$KAS_VENV_DIR")"
  python3 -m venv "$KAS_VENV_DIR"
  "$KAS_VENV_DIR/bin/pip" install --upgrade pip
  "$KAS_VENV_DIR/bin/pip" install kas
}

ensure_kas() {
  export PATH="$HOME/.local/bin:$PATH"

  if [[ -x "$KAS_VENV_DIR/bin/kas" ]]; then
    KAS_BIN="$KAS_VENV_DIR/bin/kas"
  fi

  if command_exists "$KAS_BIN"; then
    info "kas is available: $(command -v "$KAS_BIN")"
    return
  fi

  install_kas
  KAS_BIN="$KAS_VENV_DIR/bin/kas"

  if ! command_exists "$KAS_BIN"; then
    die "kas installation did not provide '$KAS_BIN' in PATH"
  fi
}

ensure_project_path() {
  mkdir -p "$YOCTO_ROOT"

  if [[ "$SOURCE_PROJECT_DIR" == "$PROJECT_DIR" ]]; then
    info "Project is already in the correct location: $PROJECT_DIR"
    return
  fi

  if [[ "$(basename "$SOURCE_PROJECT_DIR")" != "$PROJECT_NAME" ]]; then
    die "Project directory name must be $PROJECT_NAME, currently is $(basename "$SOURCE_PROJECT_DIR")."
  fi

  if [[ -e "$PROJECT_DIR" ]]; then
    die "Destination $PROJECT_DIR already exists. Please run the script from the correct directory or handle the existing directory first."
  fi

  info "Project is not in $YOCTO_ROOT, moving to $PROJECT_DIR"
  mv "$SOURCE_PROJECT_DIR" "$PROJECT_DIR"
  info "Project moved. Run the script again with:"
  printf '  %s/scripts/setup-yocto-build.sh\n' "$PROJECT_DIR"
  exit 0
}

kas_in_project() {
  (
    cd "$PROJECT_DIR"
    env KAS_WORK_DIR="$YOCTO_ROOT" KAS_BUILD_DIR="$BUILD_DIR" "$KAS_BIN" "$@"
  )
}

checkout_sources() {
  [[ -f "$KAS_MANIFEST" ]] || die "Cannot find kas manifest: $KAS_MANIFEST"

  info "Checking out Yocto sources via kas"
  kas_in_project checkout "$KAS_MANIFEST_REL"
}

prime_build_dir() {
  info "Creating/checking kas build directory: $BUILD_DIR"
  kas_in_project shell "$KAS_MANIFEST_REL" -c "true"
}

create_kas_shell_helper() {
  info "Creating kas shell helper: $YOCTO_ROOT/setup-yocto-env.sh"
  cat >"$YOCTO_ROOT/setup-yocto-env.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$PROJECT_DIR"
export PATH="\$HOME/.local/bin:\$PATH"
exec env KAS_WORK_DIR="$YOCTO_ROOT" KAS_BUILD_DIR="$BUILD_DIR" "$KAS_BIN" shell "$KAS_MANIFEST_REL"
EOF
  chmod +x "$YOCTO_ROOT/setup-yocto-env.sh"
}

main() {
  ensure_project_path
  check_dependencies
  ensure_kas
  checkout_sources
  prime_build_dir
  create_kas_shell_helper

  info "Setup completed."
  printf 'Enter the kas shell with:\n  %s/setup-yocto-env.sh\n' "$YOCTO_ROOT"
  printf 'Build the default image with:\n  cd %s && KAS_WORK_DIR=%s KAS_BUILD_DIR=%s %s build %s\n' \
    "$PROJECT_DIR" "$YOCTO_ROOT" "$BUILD_DIR" "$KAS_BIN" "$KAS_MANIFEST_REL"
}

main "$@"

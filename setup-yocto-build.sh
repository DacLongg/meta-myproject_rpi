#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME="meta-myproject_rpi"
YOCTO_ROOT="${YOCTO_ROOT:-$HOME/yocto}"
BUILD_DIR_NAME="${BUILD_DIR_NAME:-build-rpi}"
POKY_BRANCH="${POKY_BRANCH:-kirkstone}"
META_BRANCH="${META_BRANCH:-$POKY_BRANCH}"

POKY_URL="${POKY_URL:-https://git.yoctoproject.org/git/poky}"
META_RPI_URL="${META_RPI_URL:-https://github.com/agherzan/meta-raspberrypi.git}"
META_OPENEMBEDDED_URL="${META_OPENEMBEDDED_URL:-https://git.openembedded.org/meta-openembedded}"

PROJECT_DIR="$YOCTO_ROOT/$PROJECT_NAME"
BUILD_DIR="$YOCTO_ROOT/$BUILD_DIR_NAME"
PROJECT_BUILD_CONF_DIR="$PROJECT_DIR/conf/build"

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

script_dir() {
  local src
  src="${BASH_SOURCE[0]}"
  while [[ -L "$src" ]]; do
    src="$(readlink "$src")"
  done
  cd -P "$(dirname "$src")" >/dev/null 2>&1
  pwd
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
      findutils which file cpio python3-pip xz zstd lz4 bc
    )
    info "Update package build Yocto by dnf"
    run_with_sudo dnf install -y "${dnf_packages[@]}"
  elif command_exists zypper; then
    local zypper_packages=(
      python3 gcc gcc-c++ git chrpath make wget python3-xml diffstat makeinfo
      python3-curses patch socat python3-pexpect xz which tar gzip bzip2 unzip
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

ensure_project_path() {
  local current_dir
  current_dir="$(script_dir)"

  mkdir -p "$YOCTO_ROOT"

  if [[ "$current_dir" == "$PROJECT_DIR" ]]; then
    info "Project is already in the correct location: $PROJECT_DIR"
    return
  fi

  if [[ "$(basename "$current_dir")" != "$PROJECT_NAME" ]]; then
    die "Project directory name must be $PROJECT_NAME, currently is $(basename "$current_dir")."
  fi

  if [[ -e "$PROJECT_DIR" ]]; then
    die "Destination $PROJECT_DIR already exists. Please run the script from the correct directory or handle the existing directory first."
  fi

  info "Project is not in $YOCTO_ROOT, moving to $PROJECT_DIR"
  mv "$current_dir" "$PROJECT_DIR"
  info "Project moved. Run the script again with:"
  printf '  %s/setup-yocto-build.sh\n' "$PROJECT_DIR"
  exit 0
}

ensure_repo() {
  local url="$1"
  local dest="$2"
  local branch="$3"

  if [[ -d "$dest/.git" ]]; then
    info "$(basename "$dest") already exists, checking branch"
    git -C "$dest" fetch --quiet origin "$branch" || warn "Cannot fetch $dest. Continuing with current checkout."
    if git -C "$dest" rev-parse --verify --quiet "$branch" >/dev/null; then
      git -C "$dest" checkout --quiet "$branch"
    elif git -C "$dest" rev-parse --verify --quiet "origin/$branch" >/dev/null; then
      git -C "$dest" checkout --quiet -B "$branch" "origin/$branch"
    else
      warn "$dest does not have branch $branch. Skipping checkout."
    fi
  elif [[ -e "$dest" ]]; then
    die "$dest already exists but is not a git repo."
  else
    info "Clone $(basename "$dest") branch $branch"
    git clone --branch "$branch" --single-branch "$url" "$dest"
  fi
}

ensure_yocto_sources() {
  info "Checking Yocto sources in $YOCTO_ROOT"
  ensure_repo "$POKY_URL" "$YOCTO_ROOT/poky" "$POKY_BRANCH"
  ensure_repo "$META_RPI_URL" "$YOCTO_ROOT/meta-raspberrypi" "$META_BRANCH"
  ensure_repo "$META_OPENEMBEDDED_URL" "$YOCTO_ROOT/meta-openembedded" "$META_BRANCH"
}

create_build_env() {
  local init="$YOCTO_ROOT/poky/oe-init-build-env"
  [[ -f "$init" ]] || die "Cannot find $init"

  info "Creating/checking build environment: $BUILD_DIR"
  # oe-init-build-env from kirkstone reads a few optional variables that may be
  # unset, so do not source it while nounset is active.
  set +u
  # shellcheck disable=SC1090
  source "$init" "$BUILD_DIR" >/dev/null
  set -u

  info "Creating helper source env: $YOCTO_ROOT/setup-yocto-env.sh"
  cat >"$YOCTO_ROOT/setup-yocto-env.sh" <<EOF
#!/usr/bin/env bash
set -e
nounset_was_enabled=0
case \$- in
  *u*) nounset_was_enabled=1; set +u ;;
esac
source "$YOCTO_ROOT/poky/oe-init-build-env" "$BUILD_DIR"
if [[ "\$nounset_was_enabled" -eq 1 ]]; then
  set -u
fi
unset nounset_was_enabled
EOF
  chmod +x "$YOCTO_ROOT/setup-yocto-env.sh"
}

add_layer_if_missing() {
  local layer="$1"
  local bblayers="$BUILD_DIR/conf/bblayers.conf"

  [[ -f "$bblayers" ]] || die "Cannot find $bblayers"
  [[ -d "$layer" ]] || die "Cannot find layer $layer"

  if grep -Fq "$layer" "$bblayers"; then
    info "Layer is already in bblayers.conf: $layer"
  else
    info "Adding layer: $layer"
    bitbake-layers add-layer "$layer"
  fi
}

configure_layers() {
  local template="$PROJECT_BUILD_CONF_DIR/bblayers.conf.in"
  local bblayers="$BUILD_DIR/conf/bblayers.conf"

  [[ -f "$template" ]] || die "Cannot find template $template"
  [[ -f "$bblayers" ]] || die "Cannot find $bblayers"

  info "Render bblayers.conf from project template"
  sed \
    -e "s|@YOCTO_ROOT@|$YOCTO_ROOT|g" \
    -e "s|@PROJECT_NAME@|$PROJECT_NAME|g" \
    "$template" >"$bblayers"
}

configure_local_conf() {
  local template="$PROJECT_BUILD_CONF_DIR/local.conf.append"
  local local_conf="$BUILD_DIR/conf/local.conf"
  local tmp_conf

  [[ -f "$template" ]] || die "Cannot find template $template"
  [[ -f "$local_conf" ]] || die "Cannot find $local_conf"

  info "Applying project configuration block to local.conf"
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

main() {
  ensure_project_path
  check_dependencies
  ensure_yocto_sources
  create_build_env
  configure_layers
  configure_local_conf

  info "Setup completed."
  printf 'Use the build environment with:\n  source %s/setup-yocto-env.sh\n' "$YOCTO_ROOT"
  printf 'Build a test image with:\n  bitbake core-image-minimal\n'
}

main "$@"

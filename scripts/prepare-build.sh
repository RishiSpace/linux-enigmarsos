#!/usr/bin/env bash
# Validate the packaging tree and import PGP keys before makepkg.
# Does not compile the kernel.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: prepare-build.sh [--skip-keys]

Checks that the linux-enigmarsos packaging tree is complete, that the
pinned BORE patch matches its recorded checksum, and that required
build tools exist. Optionally imports the vendored kernel/Arch PGP keys.

This script does not download the kernel tarball or compile anything.
Run `makepkg -s` afterwards (see BUILDING.md).
EOF
}

SKIP_KEYS=0
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --skip-keys) SKIP_KEYS=1 ;;
    *) die "unknown argument: $arg" ;;
  esac
done

require_repo_files
verify_bore_checksum
load_bore_meta

info "linux-enigmarsos packaging tree"
printf '    package:           linux-enigmarsos %s\n' "$(package_version)"
printf '    upstream Linux:    %s\n' "$(upstream_kernel)"
printf '    tracked Arch rel:  %s\n' "$(pkgbuild_var _arch_pkgrel)"
printf '    expected release:  %s\n' "$(expected_kernel_release)"
printf '    BORE:              %s (%s, commit %s)\n' \
  "$BORE_VERSION" "$BORE_CHANNEL" "$BORE_COMMIT"
printf '    BORE designed for: Linux %s\n' "$BORE_DESIGNED_FOR_KERNEL"
printf '    BORE SHA-256:      %s\n' "$BORE_SHA256"

[[ -s "$ARCH_CONFIG" ]] || die "Arch config is empty"
[[ -s "$ENIGMARS_CONFIG" ]] || die "EnigmarsOS config fragment is empty"
grep -q '^CONFIG_SCHED_BORE=y' "$ENIGMARS_CONFIG" \
  || die "config/enigmarsos.config must set CONFIG_SCHED_BORE=y"

need_cmd makepkg
need_cmd patch
need_cmd curl
need_cmd sha256sum
need_cmd python3

if [[ "$SKIP_KEYS" -eq 0 ]] && command -v gpg >/dev/null 2>&1; then
  info "Importing vendored PGP keys"
  local_key=0
  for key in "$REPO_ROOT"/keys/pgp/*.asc; do
    [[ -f "$key" ]] || continue
    gpg --import "$key" >/dev/null 2>&1 || warn "could not import $key"
    local_key=1
  done
  [[ "$local_key" -eq 1 ]] || warn "no PGP keys found under keys/pgp"
else
  warn "skipping PGP key import"
fi

info "prepare-build: OK"
info "Next: makepkg -s"

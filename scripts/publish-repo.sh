#!/usr/bin/env bash
# Optional second-stage publisher: drop packages into a pacman repo directory.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: publish-repo.sh <repo-directory> [package-dir]

Copies the built linux-enigmarsos packages into a pacman repository
directory and runs repo-add. This is the hook a future EnigmarsOS
package repository should call. It does not upload anywhere by itself.

Required tools: repo-add (pacman)
EOF
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }
[[ $# -ge 1 ]] || { usage; exit 1; }

need_cmd repo-add
need_cmd install

DEST="$1"
PKGDIR="${2:-}"
mkdir -p "$DEST"

if [[ -z "$PKGDIR" ]]; then
  mapfile -t ALL_PKGS < <(find_built_packages || true)
else
  shopt -s nullglob
  ALL_PKGS=("$PKGDIR"/linux-enigmarsos-*.pkg.tar.zst)
  shopt -u nullglob
fi
((${#ALL_PKGS[@]})) || die "no packages to publish"

info "Publishing to $DEST"
for p in "${ALL_PKGS[@]}"; do
  install -m644 "$p" "$DEST/"
  info "copied $(basename "$p")"
done

(
  cd "$DEST"
  repo-add --new --remove linux-enigmarsos.db.tar.gz linux-enigmarsos-*.pkg.tar.zst
)

info "pacman repository updated"
echo "Add the following to /etc/pacman.conf:"
echo
echo "[linux-enigmarsos]"
echo "SigLevel = Optional TrustAll"
echo "Server = file://$DEST"
echo
echo "Then: pacman -Sy linux-enigmarsos linux-enigmarsos-headers"

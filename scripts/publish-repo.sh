#!/usr/bin/env bash
# Build a pacman repository directory from linux-enigmarsos-lts packages.
#
# GitHub Releases cannot serve symlink assets, so this materializes
# linux-enigmarsos-lts.db and linux-enigmarsos-lts.files as regular files (copies
# of the .tar.gz). Pacman can then use:
#
#   Server = https://github.com/RishiSpace/linux-enigmarsos/releases/download/lts
#
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: publish-repo.sh <repo-directory> [package-dir]

Copies linux-enigmarsos-lts *.pkg.tar.zst into <repo-directory>, runs
repo-add, and writes regular-file copies of .db / .files so the
directory can be uploaded to a GitHub Release (mirror-ready).

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
  ALL_PKGS=("$PKGDIR"/linux-enigmarsos-lts-*.pkg.tar.zst)
  shopt -u nullglob
fi
((${#ALL_PKGS[@]})) || die "no packages to publish"

info "Publishing to $DEST"
for p in "${ALL_PKGS[@]}"; do
  dest_pkg="$DEST/$(basename "$p")"
  if [[ "$(readlink -f "$p")" == "$(readlink -f "$dest_pkg")" ]]; then
    info "already in place $(basename "$p")"
    continue
  fi
  install -m644 "$p" "$DEST/"
  info "copied $(basename "$p")"
done

(
  cd "$DEST"
  rm -f linux-enigmarsos-lts.db linux-enigmarsos-lts.db.tar.gz \
        linux-enigmarsos-lts.files linux-enigmarsos-lts.files.tar.gz \
        linux-enigmarsos-lts.db.tar.gz.old linux-enigmarsos-lts.files.tar.gz.old
  repo-add --new --remove linux-enigmarsos-lts.db.tar.gz linux-enigmarsos-lts-*.pkg.tar.zst

  # GitHub Releases: upload regular files, not symlinks.
  for stem in linux-enigmarsos-lts.db linux-enigmarsos-lts.files; do
    if [[ -L "$stem" ]]; then
      target="$(readlink -f "$stem")"
      rm -f "$stem"
      cp -a "$target" "$stem"
    elif [[ -f "${stem}.tar.gz" && ! -f "$stem" ]]; then
      cp -a "${stem}.tar.gz" "$stem"
    fi
  done

  sha256sum linux-enigmarsos-lts-*.pkg.tar.zst \
    linux-enigmarsos-lts.db linux-enigmarsos-lts.db.tar.gz \
    linux-enigmarsos-lts.files linux-enigmarsos-lts.files.tar.gz \
    > SHA256SUMS 2>/dev/null || sha256sum linux-enigmarsos-lts-*.pkg.tar.zst \
    linux-enigmarsos-lts.db* > SHA256SUMS
)

info "pacman repository updated (GitHub-mirror regular files)"
echo
echo "Add the following to /etc/pacman.conf (or /etc/pacman.d/linux-enigmarsos-lts.conf):"
echo
echo "[linux-enigmarsos-lts]"
echo "SigLevel = Optional TrustAll"
echo "Server = https://github.com/RishiSpace/linux-enigmarsos/releases/download/lts"
echo "# Server = file://$DEST"
echo
echo "Then: pacman -Sy linux-enigmarsos-lts linux-enigmarsos-lts-headers"
echo
echo "Upload these assets onto the GitHub Release (same names every time):"
echo "  linux-enigmarsos-lts.db"
echo "  linux-enigmarsos-lts.db.tar.gz"
echo "  linux-enigmarsos-lts.files"
echo "  linux-enigmarsos-lts.files.tar.gz"
echo "  linux-enigmarsos-lts-*-x86_64.pkg.tar.zst"
echo "  linux-enigmarsos-lts-headers-*-x86_64.pkg.tar.zst"
echo "  SHA256SUMS"

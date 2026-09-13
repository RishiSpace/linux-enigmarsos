#!/usr/bin/env bash
# Upload a GitHub-mirror repo directory onto an existing GitHub Release.
# Requires: gh (authenticated), repo-add output from publish-repo.sh
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

need_cmd gh

TAG="${1:-}"
REPO_DIR="${2:-$REPO_ROOT/repo/x86_64}"

# LTS must not land on rolling Latest. Default tag is `lts`.
if [[ -z "$TAG" ]]; then
  TAG="lts"
fi
[[ -d "$REPO_DIR" ]] || die "repo directory missing: $REPO_DIR"
[[ -f "$REPO_DIR/linux-enigmarsos-lts.db" ]] || die "run publish-repo.sh first ($REPO_DIR/linux-enigmarsos-lts.db missing)"
[[ ! -L "$REPO_DIR/linux-enigmarsos-lts.db" ]] || die "linux-enigmarsos-lts.db must be a regular file, not a symlink"

if ! gh release view "$TAG" --repo RishiSpace/linux-enigmarsos >/dev/null 2>&1; then
  info "Creating release $TAG"
  gh release create "$TAG" --repo RishiSpace/linux-enigmarsos \
    --title "linux-enigmarsos-lts" \
    --notes "LTS ISO kernel (x86-64-v2). Rolling v3 stays on Latest."
fi

shopt -s nullglob
pkgs=("$REPO_DIR"/linux-enigmarsos-lts-*.pkg.tar.zst)
shopt -u nullglob

info "Uploading mirror assets to release $TAG from $REPO_DIR"
gh release upload "$TAG" --clobber --repo RishiSpace/linux-enigmarsos \
  "$REPO_DIR/linux-enigmarsos-lts.db" \
  "$REPO_DIR/linux-enigmarsos-lts.db.tar.gz" \
  "$REPO_DIR/linux-enigmarsos-lts.files" \
  "$REPO_DIR/linux-enigmarsos-lts.files.tar.gz" \
  "$REPO_DIR/SHA256SUMS" \
  "${pkgs[@]}"

info "Mirror URL:"
echo "  https://github.com/RishiSpace/linux-enigmarsos/releases/download/lts/linux-enigmarsos-lts.db"

#!/usr/bin/env bash
# Upload a GitHub-mirror repo directory onto an existing GitHub Release.
# Requires: gh (authenticated), repo-add output from publish-repo.sh
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

need_cmd gh

TAG="${1:-}"
REPO_DIR="${2:-$REPO_ROOT/repo/x86_64}"

if [[ -z "$TAG" ]]; then
  TAG="$(gh release list --repo RishiSpace/linux-enigmarsos --limit 20 \
    --json tagName,isLatest --jq '.[] | select(.isLatest==true) | .tagName')"
fi
[[ -n "$TAG" ]] || die "could not determine Latest release tag (pass it as argv1)"
[[ -d "$REPO_DIR" ]] || die "repo directory missing: $REPO_DIR"
[[ -f "$REPO_DIR/linux-enigmarsos.db" ]] || die "run publish-repo.sh first ($REPO_DIR/linux-enigmarsos.db missing)"
[[ ! -L "$REPO_DIR/linux-enigmarsos.db" ]] || die "linux-enigmarsos.db must be a regular file, not a symlink"

info "Uploading mirror assets to release $TAG from $REPO_DIR"
# --clobber replaces db files when republishing the same tag
gh release upload "$TAG" --clobber --repo RishiSpace/linux-enigmarsos \
  "$REPO_DIR/linux-enigmarsos.db" \
  "$REPO_DIR/linux-enigmarsos.db.tar.gz" \
  "$REPO_DIR/linux-enigmarsos.files" \
  "$REPO_DIR/linux-enigmarsos.files.tar.gz" \
  "$REPO_DIR/SHA256SUMS"

info "Mirror URL:"
echo "  https://github.com/RishiSpace/linux-enigmarsos/releases/latest/download/linux-enigmarsos.db"

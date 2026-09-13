#!/usr/bin/env bash
# Local compile, then write a GitHub-mirror pacman db in repo/x86_64.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

export MAKEFLAGS="-j2"
export PKGDEST="$PWD/out"
mkdir -p "$PKGDEST"

command -v repo-add >/dev/null 2>&1 || {
  echo "==> ERROR: repo-add not found (install pacman); needed for linux-enigmarsos-lts.db" >&2
  exit 1
}

# free RAM before starting: close browsers / other heavy apps
gpg --import keys/pgp/*.asc || true

./scripts/status.sh
./scripts/update-arch-kernel.sh
./scripts/update-bore.sh
./scripts/prepare-build.sh

makepkg -sf --noconfirm --needed

./scripts/verify-build.sh "$PKGDEST"
ls -lh "$PKGDEST"/linux-enigmarsos-lts-*.pkg.tar.zst

pkgver="$(grep -m1 '^pkgver=' PKGBUILD | cut -d= -f2 | tr -d "'\"")"
pkgrel="$(grep -m1 '^pkgrel=' PKGBUILD | cut -d= -f2 | tr -d "'\"")"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

shopt -s nullglob
built=("$PKGDEST"/linux-enigmarsos-lts{,-headers}-"${pkgver}-${pkgrel}"-*.pkg.tar.zst)
shopt -u nullglob
if ((${#built[@]} == 0)); then
  echo "==> ERROR: no packages for ${pkgver}-${pkgrel} in $PKGDEST" >&2
  exit 1
fi

# Index only this LTS build. Wipe leftover rolling packages from repo/.
repo_dir="$PWD/repo/x86_64"
mkdir -p "$repo_dir"
rm -f "$repo_dir"/linux-enigmarsos*.pkg.tar.zst \
      "$repo_dir"/linux-enigmarsos*.db \
      "$repo_dir"/linux-enigmarsos*.db.tar.gz \
      "$repo_dir"/linux-enigmarsos*.files \
      "$repo_dir"/linux-enigmarsos*.files.tar.gz \
      "$repo_dir"/linux-enigmarsos*.db.tar.gz.old \
      "$repo_dir"/linux-enigmarsos*.files.tar.gz.old \
      "$repo_dir"/SHA256SUMS
cp -a "${built[@]}" "$stage/"
./scripts/publish-repo.sh "$repo_dir" "$stage"

for f in linux-enigmarsos-lts.db linux-enigmarsos-lts.db.tar.gz \
         linux-enigmarsos-lts.files linux-enigmarsos-lts.files.tar.gz; do
  p="$repo_dir/$f"
  if [[ ! -f "$p" ]]; then
    echo "==> ERROR: missing $p" >&2
    exit 1
  fi
  if [[ -L "$p" ]]; then
    echo "==> ERROR: $p is a symlink; GitHub Releases cannot serve it" >&2
    exit 1
  fi
done

echo
ls -lh "$repo_dir"/linux-enigmarsos-lts.db "$repo_dir"/linux-enigmarsos-lts.db.tar.gz \
       "$repo_dir"/linux-enigmarsos-lts.files "$repo_dir"/linux-enigmarsos-lts.files.tar.gz
echo "Upload with: ./scripts/upload-release-mirror.sh lts"

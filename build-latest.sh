#!/usr/bin/env bash
# Check Arch linux, update this tree if we are behind, then compile.
# Default MAKEFLAGS=-j2 to stay near ~8 GiB RAM (override if you want).
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

# ~2–3 GiB per gcc/rustc job; -j2 is the 8 GiB-safe default.
export MAKEFLAGS="${MAKEFLAGS:--j2}"
export PKGDEST="${PKGDEST:-$PWD/out}"
mkdir -p "$PKGDEST"

echo "==> linux-enigmarsos local build"
echo "    MAKEFLAGS=$MAKEFLAGS"
echo "    PKGDEST=$PKGDEST"
echo

./scripts/status.sh || true
echo

arch_stale=0
./scripts/update-arch-kernel.sh --check && arch_stale=0 || {
  rc=$?
  if [[ $rc -eq 2 ]]; then
    arch_stale=1
  else
    echo "==> ERROR: could not query Arch linux packaging (exit $rc)" >&2
    exit "$rc"
  fi
}

if [[ $arch_stale -eq 1 ]]; then
  echo "==> Arch moved; updating PKGBUILD + config"
  ./scripts/update-arch-kernel.sh
  echo "==> Refreshing BORE pin for the new series"
  ./scripts/update-bore.sh
else
  echo "==> Packaging already tracks current Arch linux"
fi

echo "==> Preparing tree"
./scripts/prepare-build.sh

echo "==> Compiling (this takes a long time at $MAKEFLAGS)"
makepkg -Csf --noconfirm --needed

echo "==> Verifying packages"
./scripts/verify-build.sh "$PKGDEST"

echo
echo "==> Done"
ls -lh "$PKGDEST"/linux-enigmarsos-*.pkg.tar.zst
echo
echo "Install with:"
echo "  sudo pacman -U $PKGDEST/linux-enigmarsos-*.pkg.tar.zst"

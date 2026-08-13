#!/usr/bin/env bash
# Compare this repo with the current official Arch linux package.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

STRICT=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    -h|--help)
      echo "Usage: status.sh [--strict]"
      exit 0
      ;;
    *) die "unknown argument: $arg" ;;
  esac
done

require_repo_files
load_bore_meta

ours_pkgver="$(pkgbuild_var pkgver)"
ours_pkgrel="$(pkgbuild_var pkgrel)"
ours_arch_pkgrel="$(pkgbuild_var _arch_pkgrel)"
ours_kernel="$(upstream_kernel)"

arch_pkgver=""
arch_pkgrel=""
if arch_line="$(current_arch_linux 2>/dev/null)"; then
  arch_pkgver="${arch_line%% *}"
  arch_pkgrel="${arch_line##* }"
else
  warn "could not query archlinux.org"
fi

echo "=============================================="
echo " linux-enigmarsos status"
echo "=============================================="
echo "EnigmarsOS package:     $ours_pkgver-$ours_pkgrel"
echo "Upstream Linux:         $ours_kernel"
echo "Tracked Arch pkgrel:    $ours_arch_pkgrel"
echo "Expected uname -r:      $(expected_kernel_release)"
echo "BORE version:           $BORE_VERSION"
echo "BORE commit:            $BORE_COMMIT"
echo "BORE designed for:      $BORE_DESIGNED_FOR_KERNEL"
echo "BORE channel:           $BORE_CHANNEL"
if [[ -n "$arch_pkgver" ]]; then
  echo "Current Arch linux:     $arch_pkgver-$arch_pkgrel"
else
  echo "Current Arch linux:     (unavailable)"
fi
echo "----------------------------------------------"

status="IN SYNC"
if [[ -n "$arch_pkgver" ]]; then
  if [[ "$arch_pkgver" != "$ours_pkgver" ]]; then
    status="BEHIND"
    echo "Arch pkgver changed: $ours_pkgver -> $arch_pkgver"
    echo "Run: ./scripts/update-arch-kernel.sh && ./scripts/update-bore.sh"
  elif [[ "$arch_pkgrel" != "$ours_arch_pkgrel" ]]; then
    status="BEHIND"
    echo "Arch pkgrel changed: $ours_arch_pkgrel -> $arch_pkgrel"
    echo "Run: ./scripts/update-arch-kernel.sh"
  else
    echo "Packaging tracks the current Arch linux package."
  fi
fi

ours_major="${ours_kernel%.*}"
designed_major="${BORE_DESIGNED_FOR_KERNEL%.*}"
if [[ "$ours_major" != "$designed_major" ]]; then
  status="BORE MISMATCH"
  echo "BORE was written for ${BORE_DESIGNED_FOR_KERNEL}, this kernel is ${ours_kernel}."
  echo "Run: ./scripts/update-bore.sh"
fi

echo "Status:                 $status"
echo "=============================================="

if [[ "$STRICT" -eq 1 && "$status" != "IN SYNC" ]]; then
  exit 2
fi

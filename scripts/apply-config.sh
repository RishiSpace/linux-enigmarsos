#!/usr/bin/env bash
# Apply a Kconfig fragment onto a kernel .config using scripts/config.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: apply-config.sh <kernel-srcdir> [fragment]

Applies the EnigmarsOS Kconfig fragment (or another fragment) onto
kernel-srcdir/.config using the in-tree scripts/config helper.
EOF
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }
[[ $# -ge 1 ]] || { usage; exit 1; }

srcdir="$1"
fragment="${2:-$ENIGMARS_CONFIG}"
config="$srcdir/.config"
helper="$srcdir/scripts/config"

[[ -d "$srcdir" ]] || die "kernel source dir not found: $srcdir"
[[ -x "$helper" || -f "$helper" ]] || die "scripts/config missing in $srcdir"
[[ -f "$config" ]] || die ".config missing in $srcdir"
[[ -f "$fragment" ]] || die "fragment not found: $fragment"

info "Applying $(basename "$fragment") to $config"

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%$'\r'}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  if [[ "$line" =~ ^#\ CONFIG_([A-Za-z0-9_]+)\ is\ not\ set$ ]]; then
    "$helper" --file "$config" --disable "${BASH_REMATCH[1]}"
    continue
  fi
  if [[ "$line" =~ ^CONFIG_([A-Za-z0-9_]+)=y$ ]]; then
    "$helper" --file "$config" --enable "${BASH_REMATCH[1]}"
    continue
  fi
  if [[ "$line" =~ ^CONFIG_([A-Za-z0-9_]+)=m$ ]]; then
    "$helper" --file "$config" --module "${BASH_REMATCH[1]}"
    continue
  fi
  if [[ "$line" =~ ^CONFIG_([A-Za-z0-9_]+)=\"(.*)\"$ ]]; then
    "$helper" --file "$config" --set-str "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    continue
  fi
  if [[ "$line" =~ ^CONFIG_([A-Za-z0-9_]+)=([^[:space:]]+)$ ]]; then
    "$helper" --file "$config" --set-val "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    continue
  fi
  die "unrecognised fragment line: $line"
done < "$fragment"

info "apply-config: OK"

#!/usr/bin/env bash
# Refresh PKGBUILD version/checksums and the Arch config from official packaging.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: update-arch-kernel.sh [--check]

Fetches the official Arch linux packaging tree and updates:

  - pkgver / checksums / source tags in PKGBUILD
  - _arch_pkgrel
  - config/config.x86_64
  - keys/pgp/*

Does not commit, does not compile, and does not touch the BORE patch.

  --check   report whether an update is available, then exit
EOF
}

CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --check) CHECK_ONLY=1 ;;
    *) die "unknown argument: $arg" ;;
  esac
done

need_cmd git
need_cmd python3
need_cmd curl

ours_pkgver="$(pkgbuild_var pkgver)"
ours_arch_pkgrel="$(pkgbuild_var _arch_pkgrel)"

info "Querying current Arch linux package"
arch_line="$(current_arch_linux)"
arch_pkgver="${arch_line%% *}"
arch_pkgrel="${arch_line##* }"
echo "    this repo:  $ours_pkgver (tracked Arch pkgrel $ours_arch_pkgrel)"
echo "    Arch linux: $arch_pkgver-$arch_pkgrel"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  if [[ "$arch_pkgver" == "$ours_pkgver" && "$arch_pkgrel" == "$ours_arch_pkgrel" ]]; then
    info "already up to date"
    exit 0
  fi
  info "update available"
  exit 2
fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/enigmarsos-arch.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

clone_ok=0
info "Cloning Arch linux packaging"
if git clone --depth 1 \
    https://gitlab.archlinux.org/archlinux/packaging/packages/linux.git \
    "$WORKDIR/linux" >/dev/null 2>&1; then
  clone_ok=1
else
  warn "gitlab.archlinux.org clone failed; trying GitHub mirror"
  if git clone --depth 1 \
      https://github.com/ClangBuiltLinux/linux_pkgbuild.git \
      "$WORKDIR/linux" >/dev/null 2>&1; then
    clone_ok=1
  fi
fi
[[ "$clone_ok" -eq 1 ]] || die "could not clone Arch linux packaging"

ARCH_PKG="$WORKDIR/linux/PKGBUILD"
[[ -f "$ARCH_PKG" ]] || die "cloned tree has no PKGBUILD"

UP_pkgver="$(python3 - "$ARCH_PKG" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
def grab(name):
    m = re.search(rf'^{name}=([^\n]+)$', text, re.M)
    if not m:
        raise SystemExit(f"missing {name}")
    val = m.group(1).strip().strip("'\"")
    print(val)
grab("pkgver")
print(re.search(r'^pkgrel=([^\n]+)$', text, re.M).group(1).strip().strip("'\""))
PY
)"
UP_pkgrel="$(printf '%s\n' "$UP_pkgver" | tail -n1)"
UP_pkgver="$(printf '%s\n' "$UP_pkgver" | head -n1)"

info "Arch packaging reports $UP_pkgver-$UP_pkgrel"

# Extract checksum arrays from the official PKGBUILD.
python3 - "$ARCH_PKG" "$PKGBUILD_PATH" "$UP_pkgver" "$UP_pkgrel" <<'PY'
import re, sys
arch_path, ours_path, new_pkgver, new_pkgrel = sys.argv[1:5]
arch = open(arch_path, encoding="utf-8").read()
ours = open(ours_path, encoding="utf-8").read()

def grab_assign(text, name):
    m = re.search(rf'^{name}=([^\n]+)$', text, re.M)
    if not m:
        raise SystemExit(f"missing {name} in Arch PKGBUILD")
    return m.group(1).strip()

def grab_paren(text, name):
    m = re.search(rf'^{name}=\((.*?)\)', text, re.S | re.M)
    if not m:
        raise SystemExit(f"missing {name}=() in Arch PKGBUILD")
    return m.group(0)

new_b2 = grab_paren(arch, "b2sums")
new_sha = grab_paren(arch, "sha256sums")
new_b2_x86 = grab_paren(arch, "b2sums_x86_64")

# Keep our extra two b2sums (bore.patch, enigmarsos.config) and extra two
# sha256sums. They are the last two non-SKIP entries we appended.
ours_b2 = re.search(r'^b2sums=\((.*?)\)', ours, re.S | re.M)
ours_sha = re.search(r'^sha256sums=\((.*?)\)', ours, re.S | re.M)
if not ours_b2 or not ours_sha:
    raise SystemExit("could not find checksum arrays in our PKGBUILD")

def last_quoted(block, n):
    vals = re.findall(r"'([^']+)'", block)
    if len(vals) < n:
        raise SystemExit(f"expected at least {n} quoted checksums")
    return vals[-n:]

extra_b2 = last_quoted(ours_b2.group(1), 2)
extra_sha = last_quoted(ours_sha.group(1), 2)

def inject_extras(official_block, extras):
    # official ends with SKIP for the signature. Insert extras before the
    # closing parenthesis, after the last SKIP.
    extras_fmt = "\n        '" + "'\n        '".join(extras) + "'"
    return official_block[:-1].rstrip() + extras_fmt + ")"

merged_b2 = inject_extras(new_b2, extra_b2)
merged_sha = inject_extras(new_sha, extra_sha)

ours = re.sub(r'^pkgver=.*$', f'pkgver={new_pkgver}', ours, count=1, flags=re.M)
ours = re.sub(r'^_arch_pkgrel=.*$', f'_arch_pkgrel={new_pkgrel}', ours, count=1, flags=re.M)
ours = re.sub(r'^b2sums=\(.*?\)', merged_b2, ours, count=1, flags=re.S | re.M)
ours = re.sub(r'^sha256sums=\(.*?\)', merged_sha, ours, count=1, flags=re.S | re.M)
ours = re.sub(r'^b2sums_x86_64=\(.*?\)', new_b2_x86, ours, count=1, flags=re.S | re.M)
ours = re.sub(
    r'# Tracked Arch package:.*',
    f'# Tracked Arch package: linux {new_pkgver}-{new_pkgrel}',
    ours,
    count=1,
)
# Do not automatically bump our pkgrel; the maintainer decides rebuilds.
open(ours_path, "w", encoding="utf-8").write(ours)
print("updated PKGBUILD checksums and versions")
PY

if [[ -f "$WORKDIR/linux/config.x86_64" ]]; then
  cp "$WORKDIR/linux/config.x86_64" "$ARCH_CONFIG"
  info "updated config/config.x86_64"
elif [[ -f "$WORKDIR/linux/config" ]]; then
  cp "$WORKDIR/linux/config" "$ARCH_CONFIG"
  info "updated config/config.x86_64 from config"
else
  die "cloned packaging has no config.x86_64"
fi

if [[ -d "$WORKDIR/linux/keys/pgp" ]]; then
  mkdir -p "$REPO_ROOT/keys/pgp"
  cp "$WORKDIR/linux/keys/pgp/"*.asc "$REPO_ROOT/keys/pgp/" 2>/dev/null || true
  info "refreshed keys/pgp"
fi

info "Arch packaging synchronized to $UP_pkgver (Arch pkgrel $UP_pkgrel)"
info "Next: ./scripts/update-bore.sh"
info "Then review the diff, commit, and trigger the workflow."

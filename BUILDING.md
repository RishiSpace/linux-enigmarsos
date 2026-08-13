# Building linux-enigmarsos

Production builds happen in GitHub Actions. Use this document only for
debugging, patch development, or an emergency local release.

You need an Arch Linux (or EnigmarsOS) machine with enough disk. A
full Arch config compile is typically 15–25 GiB and 1–2 hours.

## Quick path

```bash
# 1. Confirm the tree is complete and the BORE pin matches
./scripts/prepare-build.sh

# 2. Optional: see whether Arch has moved on
./scripts/status.sh

# 3. Build both packages
makepkg -s

# 4. Validate
./scripts/verify-build.sh

# 5. Optional QEMU smoke test (needs qemu-system-x86_64 and busybox)
./scripts/qemu-smoke.sh
```

`makepkg -s` installs the `makedepends` from `PKGBUILD` (compiler,
pahole, rust, …).

## What `makepkg` actually does

1. Downloads `linux-7.1.8.tar.xz` from kernel.org and the Arch patch
   from `github.com/archlinux/linux`.
2. Verifies SHA-256 / BLAKE2 and, if the keys are in your gnupg
   keyring, the detached signatures.
3. Applies `linux-v7.1.8-arch1.patch` then `bore.patch` with
   `patch -Np1 --fuzz=0`.
4. Copies `config/config.x86_64`, enables `CONFIG_SCHED_BORE`, runs
   `olddefconfig`, and refuses to continue if the required options are
   missing.
5. Compiles `vmlinux` / modules and `bpftool`'s `vmlinux.h`.
6. Packages `linux-enigmarsos` and `linux-enigmarsos-headers`.

There is no docs package. There is no `htmldocs` build.

## PGP keys

```bash
gpg --import keys/pgp/*.asc
```

If you skip this, makepkg still checks `b2sums` / `sha256sums` and
will fail on a corrupt tarball. Signatures are `SKIP` in the checksum
arrays the same way Arch does it; `validpgpkeys` is what makepkg uses
for `.sign` files.

## Useful `makepkg` flags

```bash
# keep the src/ tree after a failed apply, to inspect .rej files
makepkg -s --noprepare   # then run prepare() by hand if you must

# faster rebuilds while iterating on packaging (not for releases)
export MAKEFLAGS="-j$(nproc)"

# write packages somewhere other than the repo root
export PKGDEST="$PWD/out"
makepkg -s
```

Do not use ccache across a compiler or kernel-version change and then
ship the result. The CI cache key includes the package version, BORE
commit, and config hashes.

## Forcing a patch-apply check without compiling

After `makepkg --nobuild` (or a failed `prepare`):

```bash
cd src/linux-7.1.8
patch -Np1 --fuzz=0 --dry-run < ../../patches/bore.patch
```

Any hunk that needs fuzz is a hard no.

## Installing a local build

```bash
sudo pacman -U linux-enigmarsos-*.pkg.tar.zst \
               linux-enigmarsos-headers-*.pkg.tar.zst
```

Keep `linux` installed. Reboot and pick the EnigmarsOS entry.

## Emergency release from a laptop

Only if GitHub Actions is down:

```bash
export SOURCE_DATE_EPOCH="$(git log -1 --pretty=%ct)"
export PACKAGER="you <you@enigmarsos>"
./scripts/prepare-build.sh
makepkg -s
./scripts/verify-build.sh
./scripts/qemu-smoke.sh
sha256sum linux-enigmarsos-*.pkg.tar.zst > SHA256SUMS
```

Attach the packages and `SHA256SUMS` to a GitHub Release **manually**
and record in the notes that the compile was local, plus `uname -m`,
compiler versions, and `SOURCE_DATE_EPOCH`. Resume CI builds as soon
as Actions is available; do not make local compiles the habit.

## Disk and RAM

- ~1.5 GiB unpacked sources
- ~10–20 GiB object files
- rustc is required because Arch's config sets `CONFIG_RUST=y`
- 16 GiB RAM is comfortable; less may need swap

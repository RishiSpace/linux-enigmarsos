# ISO integration

EnigmarsOS should treat `linux-enigmarsos` as a normal pacman
dependency. Do not copy `vmlinuz` into the ISO overlay by hand.

## Package list

In the archiso / releng profile, replace:

```
linux
linux-headers
```

with:

```
linux-enigmarsos
linux-enigmarsos-headers
linux
linux-headers
```

Keeping both is the fallback story: the live environment and the
installed system can boot EnigmarsOS (BORE) or the stock Arch kernel.

## Repository

Point the ISO's `pacman.conf` at the EnigmarsOS kernel repo (or at a
build-time file:// repo populated by `scripts/publish-repo.sh`) **before**
`mkarchiso` resolves packages.

```
[linux-enigmarsos]
SigLevel = Optional TrustAll
Server = https://repo.enigmarsos.example/$repo/$arch
```

Until that host exists, `mkarchiso` can be given a local repo created
from a GitHub Release:

```bash
mkdir -p /tmp/eos-kernel-repo
cd /tmp/eos-kernel-repo
# download the two .pkg.tar.zst files from the latest GitHub Release
repo-add linux-enigmarsos.db.tar.gz linux-enigmarsos-*.pkg.tar.zst
```

and `Server = file:///tmp/eos-kernel-repo`.

## Bootloader

- systemd-boot: `kernel-install` / `mkinitcpio` will create one entry
  per `pkgbase`. You should see `linux-enigmarsos` and `linux`.
- GRUB: `grub-mkconfig` does the same via `/usr/lib/modules/*/pkgbase`.

Title the EnigmarsOS kernel as the default and the Arch kernel as
"EnigmarsOS (Fallback)" in the ISO's bootloader snippets. The package
names stay ordinary.

## Presets

After install, `/etc/mkinitcpio.d/linux-enigmarsos.preset` is produced
from the `pkgbase` file. Do not ship a custom preset that hard-codes a
version.

## NVIDIA

Users with the proprietary driver should install `nvidia-dkms` (or
`nvidia-open-dkms`) plus `linux-enigmarsos-headers`. The headers
package provides `LINUX-HEADERS` and a `/usr/src/linux-enigmarsos`
symlink, which is what DKMS expects.

The ISO does not need a pre-built NVIDIA module.

## What not to do

- Do not put `vmlinuz-linux-enigmarsos` in the ISO git tree.
- Do not drop the Arch `linux` package from the profile.
- Do not `Conflicts: linux` — the PKGBUILD already refuses to do that.

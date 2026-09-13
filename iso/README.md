# ISO integration

EnigmarsOS should treat `linux-enigmarsos` as a normal pacman
dependency. Do not copy `vmlinuz` into the ISO overlay by hand.

## Package list

Live ISO default (this branch):

```
linux-enigmarsos-lts
linux-enigmarsos-lts-headers
```

Keep stock `linux` as a live fallback if you want. Rolling
`linux-enigmarsos` is **not** the live default; Calamares pulls it at
install time from `main` / GitHub Latest.

## Repository

GitHub Releases **are** the pacman repo. Point the ISO `pacman.conf` at
Latest **before** `mkarchiso` / `pacstrap`:

```
[linux-enigmarsos]
SigLevel = Optional TrustAll
Server = https://github.com/RishiSpace/linux-enigmarsos/releases/latest/download
```

For an offline / pinned ISO build, snapshot Latest into a `file://` repo:

```bash
mkdir -p /tmp/eos-kernel-repo
cd /tmp/eos-kernel-repo
base=https://github.com/RishiSpace/linux-enigmarsos/releases/latest/download
# packages + db from the Latest release, or:
#   ./scripts/publish-repo.sh /tmp/eos-kernel-repo /path/to/packages
curl -fL -O "$base/linux-enigmarsos.db"
# mkarchiso also needs the .pkg.tar.zst files from the same release
```

`Server = file:///tmp/eos-kernel-repo` after downloading the packages
and db together.

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

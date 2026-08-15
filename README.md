# linux-enigmarsos

Custom Linux kernel package for **EnigmarsOS**, an independent Arch
Linux-based distribution.

This is **not** a kernel fork. The package is:

```
official Arch Linux `linux` package
        + BORE scheduler patch
        + a tiny EnigmarsOS configuration fragment
```

## Why BORE

EnigmarsOS ships KDE Plasma as its desktop. BORE (Burst-Oriented
Response Enhancer) is a small, actively maintained patch on top of the
upstream EEVDF scheduler. It scores how "bursty" each task is and gives
interactive work a better chance of staying responsive when the machine
is also compiling, encoding, or otherwise busy.

It is a scheduler tweak, not a rewrite. The rest of the kernel stays
aligned with Arch.

Upstream project: <https://github.com/firelzrd/bore-scheduler>

## What this repository tracks

| Item | Current pin |
| --- | --- |
| Upstream Linux | 7.1.8 |
| Arch `linux` package | 7.1.8.arch1-3 |
| EnigmarsOS package | `linux-enigmarsos 7.1.8.arch1-1` |
| Kernel release string | `7.1.8-arch1-1-enigmarsos` |
| BORE | 6.8.0 (`6a52aac2deab3faebcae97a34bb3eec4b3c2967e`) |
| BORE written for | Linux 7.1.5 |
| BORE channel | testing (only 7.1-series patch that applies to 7.1.8) |

Check live status:

```bash
./scripts/status.sh
```

## How it differs from Arch `linux`

| | Arch `linux` | `linux-enigmarsos` |
| --- | --- | --- |
| Source | vanilla + Arch patch | the same, then BORE |
| Config | Arch `config.x86_64` | Arch config + `CONFIG_SCHED_BORE=y` |
| Package name | `linux` / `linux-headers` | `linux-enigmarsos` / `linux-enigmarsos-headers` |
| `uname -r` | `7.1.8-arch1-3` | `7.1.8-arch1-1-enigmarsos` |
| Conflicts with `linux` | n/a | **no** — both can be installed |
| Docs package | yes | not built (saves CI time) |

Hardware support is not stripped. NVIDIA (nouveau + DKMS), AMD GPU/CPU,
Intel, KVM, containers, common filesystems, USB, Bluetooth, Wi-Fi, NVMe,
laptops, external displays, and suspend/resume stay at the Arch values.

Every configuration change is listed in [`config/CONFIG_CHANGES.md`](config/CONFIG_CHANGES.md).

## Compatibility notes

These were verified before this pin was committed. They are not
guarantees about future kernel releases.

- BORE 6.8.0 (testing, labelled for 7.1.5) applies to vanilla 7.1.8 plus
  the Arch `v7.1.8-arch1` patch with **line offsets only, zero fuzz**.
- The older stable patch `0001-linux7.1-rc1-bore-6.6.3.patch` **does
  not** apply to 7.1.8 (failed hunk in `kernel/sched/fair.c`).
- Arch's own patch touches `kernel/fork.c`, which BORE also touches.
  The hunks do not overlap. Apply order is Arch first, BORE second.
- If a future Arch kernel or BORE release stops applying cleanly, the
  build **fails**. The patch is never skipped.

## How it is built

```
Checkout
   → Arch container (pinned digest)
   → prepare-build.sh (files + BORE checksum)
   → makepkg (Arch patch, BORE --fuzz=0, EnigmarsOS config)
   → verify-build.sh (packages, metadata, CONFIG_SCHED_BORE, release string)
   → mkinitcpio
   → qemu-smoke.sh (TCG boot, read /proc/sys/kernel/sched_bore)
   → FAIL: stop, no release
   → PASS: artefacts + GitHub Release
```

Locally, for debugging only:

```bash
./scripts/prepare-build.sh
makepkg -s
./scripts/verify-build.sh
```

See [BUILDING.md](BUILDING.md).

## GitHub Actions

Workflow: [`.github/workflows/build.yml`](.github/workflows/build.yml)

The compile runs in the official `archlinux:base-devel` image, **pinned
by digest**, on a GitHub-hosted `ubuntu-latest` runner. Ubuntu is only
the host; packages are produced by Arch `makepkg`.

### Fortnightly automatic builds

The workflow is scheduled at **04:00 UTC on the 1st and 15th** of each
month:

```yaml
schedule:
  - cron: '0 4 1,15 * *'
```

Change that one line to move the window.

A scheduled run that would rebuild an already-published
`v<pkgver>-<pkgrel>` tag is skipped unless you set `force_rebuild`.
Bump `pkgrel` (or change the version) when the packaging inputs change.

### Manual builds

Actions → **Build linux-enigmarsos** → **Run workflow**.

| Input | Default | Meaning |
| --- | --- | --- |
| `force_rebuild` | true | Rebuild even if that version was already released |
| `publish` | true | Create a GitHub Release (`false` = artefacts only) |
| `kernel_version` | empty | Must match `PKGBUILD` `pkgver` if set |
| `bore_version` | empty | Must match `patches/bore.meta` if set |

`kernel_version` / `bore_version` are pin checks, not download
overrides. Changing the kernel still happens in git, via the update
scripts, so a release is always built from a committed tree.

Pushes to `main` that touch packaging files also build and publish.
Pull requests build and upload artefacts but do **not** create a
release.

### Releases

Every successful compile that has `publish=true` creates a GitHub
Release. Failed builds never publish.

Tag scheme:

- `v7.1.8.arch1-1` — first release of that package version
- `v7.1.8.arch1-1+gha.<run_id>` — a later compile of the same version

Release assets:

- `linux-enigmarsos-*.pkg.tar.zst`
- `linux-enigmarsos-headers-*.pkg.tar.zst`
- `SHA256SUMS`, `B2SUMS`
- `BUILD-METADATA.txt`
- `initramfs-linux-enigmarsos.img` (CI-generated, for inspection)

The notes record the EnigmarsOS version, upstream Linux, Arch package,
BORE version/commit, git SHA, and whether the run was scheduled or
manual.

Workflow artefacts are also kept for 14 days for CI inspection.

## Installing the packages

From a release:

```bash
sudo pacman -U linux-enigmarsos-7.1.8.arch1-1-x86_64.pkg.tar.zst \
              linux-enigmarsos-headers-7.1.8.arch1-1-x86_64.pkg.tar.zst
```

Or, once an EnigmarsOS pacman repository exists, see
[`repo/README.md`](repo/README.md).

`mkinitcpio` / `kernel-install` discover the kernel through
`/usr/lib/modules/<release>/pkgbase` (`linux-enigmarsos`). DKMS modules
build against `linux-enigmarsos-headers` the same way they do against
`linux-headers`.

## Fallback: keep the Arch kernel

Do **not** remove `linux` / `linux-headers`.

A typical install has both:

```
linux-enigmarsos     →  EnigmarsOS
linux                →  EnigmarsOS (Fallback)
```

systemd-boot and GRUB both pick up every kernel under `/usr/lib/modules`
that has a `pkgbase` file. If the EnigmarsOS kernel misbehaves, boot
the `linux` entry.

To recover from a machine that only has the broken kernel:

```bash
# from a live ISO or a working TTY
pacman -S linux linux-headers
# or boot the already-installed linux fallback entry
```

## Updating to a newer Arch kernel

```bash
./scripts/status.sh
./scripts/update-arch-kernel.sh
./scripts/update-bore.sh
# review the diff, especially patches/bore.patch
git commit
# Actions → Run workflow, or wait for the fortnightly schedule
```

If `update-bore.sh` cannot find a patch for the new series, **stop**.
Do not hand-edit scheduler code to "make it apply".

Details: [MAINTAINING.md](MAINTAINING.md).

## Repository layout

```
PKGBUILD
bore.patch -> patches/bore.patch          # makepkg local source
enigmarsos.config -> config/enigmarsos.config
config.x86_64 -> config/config.x86_64
config/config.x86_64          # vendored Arch baseline
config/enigmarsos.config      # tiny fragment
config/CONFIG_CHANGES.md
patches/bore.patch            # pinned verbatim BORE patch
patches/bore.meta
scripts/                      # update, prepare, verify, CI, QEMU
.github/workflows/build.yml
keys/pgp/                     # kernel.org + Arch packager keys
repo/                         # future pacman repo notes
iso/                          # ISO integration notes
```

The Linux source tree is **not** stored here.

## Versioning

```
package version   = <upstream>.<arch-tag>-<enigmarsos-pkgrel>
                  = 7.1.8.arch1-1
uname -r          = 7.1.8-arch1-1-enigmarsos
BORE              = recorded in patches/bore.meta, not in pkgver
```

- Bump `pkgver` when Arch's `pkgver` changes.
- Bump `pkgrel` when BORE, the EnigmarsOS fragment, or packaging
  changes on the same upstream version.
- `_arch_pkgrel` records which Arch `linux` pkgrel the config was
  copied from.

## Security

See [SECURITY.md](SECURITY.md). Sources are checksummed and
signature-verified. Secrets never belong in this repository.

## License

Mixed. Packaging is 0BSD (same as Arch's PKGBUILD). The kernel is
GPL-2.0-only with the Linux syscall note. BORE is GPL-2.0-only. See
[LICENSE](LICENSE).

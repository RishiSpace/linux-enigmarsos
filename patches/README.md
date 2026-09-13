# Patches (LTS branch)

`linux-enigmarsos-lts` is not a kernel fork. First-party source
modifications are the pinned BORE patch plus the Arch `linux-lts`
patches copied from Arch packaging.

## Arch `linux-lts` patches

| File | From |
| --- | --- |
| `0001-add-sysctl-to-allow-disabling-unprivileged-CLONE_NEW.patch` | Arch `linux-lts` |
| `0002-drm-amdgpu-avoid-memory-allocation-in-the-critical-c.patch` | Arch `linux-lts` |
| `0003-drm-amdgpu-use-GFP_ATOMIC-instead-of-NOWAIT-in-the-c.patch` | Arch `linux-lts` |

Refresh with `./scripts/update-arch-kernel.sh`. Do not edit by hand.

## `bore.patch`

| Field | Value |
| --- | --- |
| Implementation | [firelzrd/bore-scheduler](https://github.com/firelzrd/bore-scheduler) |
| BORE version | 6.8.0 |
| Written for | Linux 6.18.48 |
| Applied to | Arch `linux-lts 6.18.51` (vanilla 6.18.51 + Arch patches) |
| Channel | testing |
| Upstream path | `patches/testing/0001-linux6.18.48-bore-6.8.0.patch` |
| License | GPL-2.0-only |

`PKGBUILD` applies every `*.patch` in `source=` with `patch -Np1 --fuzz=0`.
Arch patches first, BORE last. A context mismatch fails the build.

## Apply order

1. Arch `0001` / `0002` / `0003`
2. `bore.patch`

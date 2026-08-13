# Patches

`linux-enigmarsos` is not a kernel fork. The only first-party source
modification is the pinned BORE patch.

## `bore.patch`

| Field | Value |
| --- | --- |
| Implementation | [firelzrd/bore-scheduler](https://github.com/firelzrd/bore-scheduler) |
| BORE version | 6.8.0 |
| Upstream commit | `6a52aac2deab3faebcae97a34bb3eec4b3c2967e` (2026-07-28) |
| Written for | Linux 7.1.5 |
| Applied to | Arch `linux 7.1.8.arch1` (vanilla 7.1.8 + Arch patch) |
| Channel | testing (newest 7.1-series patch that applies) |
| License | GPL-2.0-only |
| SHA-256 | `ec1edcf30028d605edafe3a7fc634870f41e5cac7a66ecdd1198e2ac4ef6a634` |

The file is an unmodified copy of
`patches/testing/0001-linux7.1.5-bore-6.8.0.patch`.

`PKGBUILD` applies it with `patch -Np1 --fuzz=0`. Any context mismatch
fails the build. The patch is never skipped and never applied with
fuzz.

## Why the testing patch, not `patches/stable/linux-7.1-bore`

The stable 7.1 file is `0001-linux7.1-rc1-bore-6.6.3.patch`. A dry-run
against 7.1.8 + the Arch patch failed in `kernel/sched/fair.c`.

The 6.8.0 testing patch applied cleanly (offsets only, zero fuzz) to
the same tree. That is the pin.

## Adding more patches

Do not add drive-by kernel patches. If a future EnigmarsOS change is
required:

1. Put a new file in this directory.
2. Add it to the `source` and checksum arrays in `PKGBUILD` after
   `bore.patch`.
3. Document why it exists and which upstream it comes from.
4. Keep applying with `--fuzz=0`.

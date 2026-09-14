# EnigmarsOS LTS kernel configuration changes

The kernel configuration starts from the official Arch Linux `linux-lts`
`config.x86_64` for the tracked package version.

This file records every deliberate EnigmarsOS change. If an option is
not listed here, it is inherited from Arch.

Hardware support is not disabled because a particular developer machine
does not use it.

## Tracked Arch baseline

| Field | Value |
| --- | --- |
| Arch package | `linux-lts 6.18.51-1` |
| Config file | `config/config.x86_64` |
| Arch config b2sum | `137a4595872b4d495582a4629fad6d04b6e4cf5dc1599a701bc26785c1df8279b3daba4edb480ba2c1f33853bc2e70ad45cfbc91532e2b6bbcf7fe45aa9704bb` |

Refresh the baseline with `./scripts/update-arch-kernel.sh` (clones
`linux-lts` packaging on this branch).

## Changes

### `CONFIG_SCHED_BORE`

| | |
| --- | --- |
| Old value | unset (option does not exist in the Arch kernel) |
| New value | `y` |
| Reason | Enable BORE, the only intentional scheduler change. |

### `CONFIG_X86_NATIVE_CPU`

| | |
| --- | --- |
| Old value | unset |
| New value | unset (forced) |
| Reason | A native build would only run on the builder. |

### Compiler ISA floor: `x86-64-v2`

Vanilla 6.18 `arch/x86/Makefile` hardcodes `-march=x86-64 -mtune=generic`.
This branch rewrites that line (and the matching rustc `-Ctarget-cpu`) to
**`x86-64-v2`** in `PKGBUILD` `prepare()`.

| | |
| --- | --- |
| Old value | `-march=x86-64` |
| New value | `-march=x86-64-v2` |
| Reason | Live ISO + GitHub Actions DKMS must run on x86-64-v2 CPUs. Rolling `main` stays v3. |

v2 is SSE4.2 (Intel Nehalem 2008+, Silvermont, AMD Bulldozer+). Kernel
SIMD stays off (`-mno-avx` is still applied first).

Host tools that ship in `linux-enigmarsos-lts-headers` (`fixdep`,
`modpost`, …) are compiled with `-march=x86-64-v2`. CachyOS `Scrt1.o`
still tags the linked ELF as `x86 ISA needed: … v4`. `PKGBUILD`
`objcopy --remove-section=.note.gnu.property` on those tools so GitHub
Actions glibc will run them. Without that, DKMS dies with
`CPU ISA level is lower than required` even when the kernel is v2.

Do **not** raise this branch to v3.

### `CONFIG_MIN_BASE_SLICE_NS`

| | |
| --- | --- |
| Old value | unset |
| New value | `2000000` |
| Reason | BORE Kconfig default; pin so `olddefconfig` cannot drop it. |

## Adding a new change

1. Add the option to `config/enigmarsos.config`.
2. Document it here with old value, new value, and reason.
3. Add the same option to the required-option list in `PKGBUILD`.
4. Do not paste a full replacement `.config`.

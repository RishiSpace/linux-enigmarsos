# EnigmarsOS kernel configuration changes

The kernel configuration starts from the official Arch Linux `linux`
`config.x86_64` for the tracked package version.

This file records every deliberate EnigmarsOS change. If an option is
not listed here, it is inherited from Arch.

Hardware support is not disabled because a particular developer machine
does not use it. NVIDIA, AMD, Intel, virtualization, containers,
networking, filesystems, USB, Bluetooth, Wi-Fi, NVMe, laptops, external
displays, and suspend/resume remain as Arch configured them.

## Tracked Arch baseline

| Field | Value |
| --- | --- |
| Arch package | `linux 7.1.8.arch1-3` |
| Config file | `config/config.x86_64` |
| Arch config b2sum | `b10d80423aa3eb65e2046bf5b1998f9a7bdbc97494c6881881f50ffcdb5fe2e242782f59dbb6402cd77ce64b988dbf295fd9fa54f20180c76fbe88b82e1dbc9d` |

Refresh the baseline with `./scripts/update-arch-kernel.sh`.

## Changes

### `CONFIG_SCHED_BORE`

| | |
| --- | --- |
| Old value | unset (option does not exist in the Arch kernel) |
| New value | `y` |
| Reason | Enable BORE (Burst-Oriented Response Enhancer), the only intentional scheduler change in `linux-enigmarsos`. |

The BORE patch defaults this option to `y`. EnigmarsOS still sets it
explicitly and fails the build if the option is missing or not `y`
after `olddefconfig`.

### `CONFIG_MIN_BASE_SLICE_NS`

| | |
| --- | --- |
| Old value | unset (option does not exist in the Arch kernel) |
| New value | `2000000` |
| Reason | BORE adds this Kconfig option. The value is the patch default: a 2 ms lower bound for the EEVDF base slice so high `HZ` does not overschedule. Pinning it prevents `olddefconfig` from dropping a newly introduced symbol. |

## Options intentionally left at the Arch value

These are commonly tempting desktop tweaks. They are already set the
way a general-purpose Arch desktop kernel expects, so EnigmarsOS does
not override them.

| Option | Arch value | Why unchanged |
| --- | --- | --- |
| `CONFIG_HZ` / `CONFIG_HZ_1000` | 1000 | Arch already uses 1000 Hz. |
| `CONFIG_PREEMPT` / `CONFIG_PREEMPT_DYNAMIC` | enabled | Arch already uses voluntary/full dynamic preempt. |
| `CONFIG_SCHED_CLASS_EXT` | `y` | Keep sched-ext userspace schedulers available. |
| `CONFIG_IKCONFIG` / `CONFIG_IKCONFIG_PROC` | `y` | Required for BORE verification via `/proc/config.gz`. |
| Compiler `-O3`, LTO, native march | off / generic | Not benchmarked for EnigmarsOS; changing them would also break the generic ISO kernel. |
| `CONFIG_RUST` | `y` | Matches Arch; required to keep their config valid. |

## Adding a new change

1. Add the option to `config/enigmarsos.config`.
2. Document it in this file with old value, new value, and reason.
3. Add the same option to the required-option list in `scripts/lib.sh`
   and `PKGBUILD`.
4. Do not paste a full replacement `.config`.

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

### `CONFIG_X86_NATIVE_CPU`

| | |
| --- | --- |
| Old value | unset (`# CONFIG_X86_NATIVE_CPU is not set`) |
| New value | unset (forced) |
| Reason | A native build would use `-march=native` and only run on the builder. EnigmarsOS needs one ISO kernel for all supported PCs. |

### Compiler ISA floor: `x86-64-v3`

Vanilla Linux 7.2 has no `CONFIG_X86_64_VERSION`. `arch/x86/Makefile` hardcodes `-march=x86-64 -mtune=generic`. EnigmarsOS rewrites that line (and the matching rustc `-Ctarget-cpu`) to **`x86-64-v3`** in `PKGBUILD` `prepare()`.

| | |
| --- | --- |
| Old value | `-march=x86-64` (every 64-bit PC) |
| New value | `-march=x86-64-v3` |
| Reason | EnigmarsOS targets modern desktops. v3 is AVX2: Intel Haswell (2013)+ and AMD Excavator (2015)+ / all Zen. Kernel SIMD stays off (`-mno-avx` is still applied first); v3 mainly enables BMI2, LZCNT, MOVBE and better scheduling. |

This kernel will not boot on Sandy/Ivy Bridge, AVX-less Pentium/Celeron, or VMs that hide AVX2 (`qemu64` / `kvm64`). Keep Arch `linux` as the Limine fallback. Point VMs at host CPU passthrough.

Do **not** default to v4 or znver4: v4 needs AVX-512 (missing on many Intel 12th–14th gen chips); znver4 is AMD-only.

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
| Compiler `-O3`, LTO | off | Not benchmarked for EnigmarsOS. |
| `-march=native` | off | Would bind the ISO kernel to one CPU. ISA floor is v3 instead. |
| `CONFIG_RUST` | `y` | Matches Arch; required to keep their config valid. |

## Adding a new change

1. Add the option to `config/enigmarsos.config`.
2. Document it in this file with old value, new value, and reason.
3. Add the same option to the required-option list in `scripts/lib.sh`
   and `PKGBUILD`.
4. Do not paste a full replacement `.config`.

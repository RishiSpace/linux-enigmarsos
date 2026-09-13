# linux-enigmarsos (LTS branch)

This branch packages **`linux-enigmarsos-lts`**: the live-ISO kernel for
EnigmarsOS.

```
official Arch Linux `linux-lts` package
        + BORE scheduler patch
        + a tiny EnigmarsOS configuration fragment
        + x86-64-v2 compiler ISA floor
```

Rolling **`linux-enigmarsos`** (x86-64-v3) stays on `main` and is pulled
at install time. Do not mix the two PKGBUILDs.

## Why LTS + v2

The ISO is built on GitHub Actions (x86-64-v2). A v3 `fixdep` from
rolling headers cannot run there, so NVIDIA DKMS never produces
`nvidia.ko` for the live default kernel. LTS v2 is the live kernel;
rolling v3 is installed by Calamares on the target PC.

## What this branch tracks

| Item | Current pin |
| --- | --- |
| Upstream Linux | 6.18.51 |
| Arch `linux-lts` package | 6.18.51-1 |
| EnigmarsOS package | `linux-enigmarsos-lts 6.18.51-1` |
| Kernel release string | `6.18.51-1-enigmarsos-lts` |
| CPU ISA | **x86-64-v2** (SSE4.2: Nehalem / Silvermont / Bulldozer+) |
| BORE | 6.8.0 (`0001-linux6.18.48-bore-6.8.0.patch`) |

```bash
./scripts/status.sh
```

## How it differs

| | Arch `linux-lts` | `linux-enigmarsos-lts` | `linux-enigmarsos` (`main`) |
| --- | --- | --- | --- |
| Source | vanilla 6.18 LTS + Arch patches | the same, then BORE | Arch `linux` 7.x + BORE |
| CPU ISA | generic `x86-64` | **x86-64-v2** | **x86-64-v3** |
| Package | `linux-lts` | `linux-enigmarsos-lts` | `linux-enigmarsos` |
| Role | Arch LTS | live ISO default | installed rolling kernel |

Does **not** conflict with `linux`, `linux-lts`, or `linux-enigmarsos`.

## Build

Same loop as `main`: `./scripts/prepare-build.sh` then `makepkg -s`.
See [`BUILDING.md`](BUILDING.md). Do not compile from this checkout
unless you intend to ship the LTS ISO kernel.

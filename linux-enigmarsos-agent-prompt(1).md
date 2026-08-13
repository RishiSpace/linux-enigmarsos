# Agent Task: Design, Patch, Build and Maintain `linux-enigmarsos`

You are an expert Linux kernel engineer, Arch Linux package maintainer, CI/CD engineer, and open-source distribution developer.

Your task is to design and implement **`linux-enigmarsos`**, the custom Linux kernel package for **EnigmarsOS**, an independent Arch Linux-based distribution.

The goal is NOT to create an independent Linux kernel fork.

Instead, `linux-enigmarsos` must remain closely aligned with the current Arch Linux kernel package while applying carefully maintained EnigmarsOS-specific modifications, most importantly the **BORE scheduler**.

The resulting system must be reproducible, maintainable, automatically updated, and suitable for inclusion in official EnigmarsOS ISO releases.

---

## 1. Project Context

EnigmarsOS is an independent Arch Linux-based Linux distribution using KDE Plasma as its desktop environment.

Currently, EnigmarsOS simply installs the standard Arch Linux `linux` kernel.

We want to introduce:

- `linux-enigmarsos`
- `linux-enigmarsos-headers`

The kernel should primarily be:

> Current Arch Linux kernel + EnigmarsOS kernel configuration + BORE scheduler patch

Do NOT unnecessarily fork or diverge from upstream Linux.

The Arch Linux kernel package should remain the primary reference/base.

The system should be designed so that updating to newer Arch kernel releases is straightforward.

---

# 2. Primary Technical Objective

Create a reproducible Arch Linux kernel package named:

`linux-enigmarsos`

and its corresponding headers package:

`linux-enigmarsos-headers`

The package must:

1. Track the current Arch Linux `linux` package.
2. Apply BORE cleanly.
3. Preserve as much of Arch's existing kernel configuration as practical.
4. Add only deliberate EnigmarsOS-specific configuration changes.
5. Produce normal Arch `.pkg.tar.zst` packages.
6. Be installable through `pacman`.
7. Work correctly with DKMS/external kernel modules where applicable.
8. Generate the correct kernel modules, firmware expectations, headers, and metadata.
9. Integrate cleanly into an EnigmarsOS ISO.
10. Be reproducible through CI.

---

# 3. Do NOT Create an Unmaintainable Kernel Fork

This is extremely important.

Do NOT:

- copy the entire Linux source tree into the EnigmarsOS repository;
- manually maintain thousands of unrelated kernel changes;
- randomly alter upstream Linux behaviour;
- permanently diverge from Arch Linux without justification;
- replace Arch's kernel configuration wholesale without understanding the consequences.

Instead, maintain:

Arch Linux kernel package
+
EnigmarsOS patches
+
EnigmarsOS configuration

The repository should contain the minimum amount of custom material required to reproduce the package.

Prefer:

- PKGBUILD
- kernel configuration
- patches/
- scripts/
- CI configuration
- documentation

over storing a gigantic modified Linux source tree.

---

# 4. BORE Integration

The primary custom kernel modification is **BORE (Burst-Oriented Response Enhancer)**.

Research the current, actively maintained BORE implementation and determine the correct way to apply it to the current Arch kernel version.

Do NOT blindly assume that an old BORE patch applies to the current kernel.

The agent must:

1. Determine the current upstream/Arch kernel version being targeted.
2. Determine the compatible BORE patch/version.
3. Verify patch applicability.
4. Apply the patch during the kernel package build process.
5. Ensure the BORE-related configuration options are enabled correctly.
6. Document exactly which BORE version/commit is being used.
7. Record the upstream Linux kernel version against which the patch was designed.
8. Fail the build if the patch no longer applies cleanly rather than silently producing an incorrectly patched kernel.

If the existing BORE implementation is incompatible with the current Arch kernel, **stop and report the incompatibility instead of inventing an unsafe patch**.

---

# 5. Kernel Configuration

Start from the Arch Linux kernel configuration.

Do not blindly replace it.

Create an EnigmarsOS-specific configuration layer that changes only the options required for:

- BORE;
- desktop responsiveness where justified;
- modern hardware support;
- EnigmarsOS requirements;
- compatibility with common Arch software;
- NVIDIA GPU support;
- AMD CPU systems;
- virtualization;
- containers;
- networking;
- filesystems;
- USB;
- Bluetooth;
- Wi-Fi;
- NVMe;
- modern laptops;
- external monitors;
- suspend/resume.

Do not disable hardware support simply because the current developer's machine does not use it.

The kernel is intended for general EnigmarsOS users.

Every non-obvious configuration change must be documented with:

CONFIG_OPTION
Old value
New value
Reason

Avoid unnecessary optimisation flags or experimental kernel configuration changes unless they are benchmarked and justified.

---

# 6. Kernel Naming

The resulting kernel must identify itself clearly as EnigmarsOS.

Use a sensible package/kernel naming scheme such as:

linux-enigmarsos
linux-enigmarsos-headers

The kernel release string should clearly distinguish it from the stock Arch kernel without breaking:

- DKMS;
- initramfs generation;
- kernel module lookup;
- bootloader discovery;
- package management;
- external kernel modules.

Do not invent an unnecessarily complicated versioning system.

The upstream kernel version should remain visible.

For example, a suitable release identity might conceptually resemble:

6.x.y-enigmarsos

but determine the technically safest implementation based on Arch's packaging conventions.

---

# 7. Repository Structure

Design a clean repository.

A reasonable starting structure is:

linux-enigmarsos/
├── PKGBUILD
├── config/
│   └── config
├── patches/
│   └── bore.patch
├── scripts/
│   ├── update-arch-kernel.sh
│   ├── update-bore.sh
│   ├── prepare-build.sh
│   └── verify-build.sh
├── .github/
│   └── workflows/
│       └── build.yml
├── README.md
├── BUILDING.md
├── SECURITY.md
├── LICENSE
└── .gitignore

Modify this structure if a better architecture is justified.

---

# 8. Arch Kernel Synchronisation

The project must have a reliable method for tracking Arch Linux kernel updates.

The system should be able to determine:

Current Arch kernel version
Current EnigmarsOS kernel version
Current BORE patch version

and identify when an update is required.

Prefer consuming the official Arch kernel packaging sources rather than manually downloading arbitrary Linux tarballs unless there is a strong technical reason otherwise.

The agent must research the current Arch packaging mechanism and use the most appropriate supported approach.

---

# 9. Automated Update Strategy

Design the repository so that kernel updates can be incorporated safely.

The desired lifecycle is:

Arch kernel changes
        ↓
EnigmarsOS maintenance detects update
        ↓
Update PKGBUILD/configuration
        ↓
Update BORE patch
        ↓
Apply patches
        ↓
Validate configuration
        ↓
Build
        ↓
Test
        ↓
Publish package

If a BORE patch stops applying:

BUILD MUST FAIL

Do not silently remove BORE.

Do not silently skip the patch.

Do not publish a kernel that claims to be `linux-enigmarsos` but lacks its intended scheduler modifications.

---

# 10. GitHub Actions Requirement

This is a mandatory requirement.

**The actual kernel compilation MUST happen in GitHub Actions.**

Do not require the developer's local machine to compile the kernel for normal releases.

The repository must contain a GitHub Actions workflow:

.github/workflows/build.yml

which performs the complete build.

---

# 11. Fortnightly Automatic Builds

The GitHub Actions workflow must automatically run **once every fortnight (every two weeks)**.

Use GitHub Actions' scheduled workflow functionality.

Do NOT rely on a developer remembering to run the build.

The schedule should be easy to modify later.

Document the schedule in the repository.

---

# 12. Manual Build Trigger

The exact same GitHub Actions workflow must also support manual execution.

Use:

workflow_dispatch:

This is mandatory.

A developer must be able to open GitHub Actions and manually trigger:

Build linux-enigmarsos

without modifying the repository.

If practical, provide useful manual inputs such as:

- force_rebuild
- kernel_version
- bore_version
- publish

but do not add unnecessary complexity.

---

# 13. Build Workflow

The GitHub Actions workflow should approximately perform:

Checkout repository
        ↓
Install Arch Linux build environment
        ↓
Install build dependencies
        ↓
Fetch/synchronise Arch kernel packaging
        ↓
Fetch/verify BORE patch
        ↓
Apply patches
        ↓
Apply EnigmarsOS configuration
        ↓
Validate configuration
        ↓
Build kernel packages
        ↓
Run package validation
        ↓
Run kernel sanity checks
        ↓
Upload build artifacts
        ↓
Optionally publish packages

The workflow must fail immediately if:

- the BORE patch cannot be applied;
- the kernel configuration is invalid;
- required files are missing;
- package creation fails;
- package metadata is invalid;
- expected kernel artefacts are missing.

---

# 14. Do Not Assume GitHub's Ubuntu Runner Is Sufficient

The build target is Arch Linux.

Therefore investigate the best way to create a reliable Arch build environment inside GitHub Actions.

Possible approaches include:

- Arch Linux container;
- Docker/Podman;
- a container image based on `archlinux`;
- a suitable Arch-based build environment;
- another reproducible mechanism.

Prefer the simplest reliable solution.

Do NOT make the workflow dependent on obscure undocumented hacks.

The build environment itself should be version-pinned wherever practical.

---

# 15. Build Performance

The kernel compilation is CPU-intensive.

Optimise the GitHub Actions workflow where possible.

Investigate:

- compiler caching;
- dependency caching;
- package caching;
- build caching;
- avoiding unnecessary source downloads;
- avoiding unnecessary rebuilds.

However:

**Correctness takes priority over caching.**

Never reuse cached objects in a way that can result in a package being built from the wrong source, configuration, patch set, or compiler environment.

---

# 16. Artifact Handling and GitHub Releases

**Every successful kernel compilation MUST be published as a GitHub Release.**

This is mandatory for both:

- fortnightly scheduled builds;
- manually triggered builds.

Every successful build must produce:

linux-enigmarsos-*.pkg.tar.zst
linux-enigmarsos-headers-*.pkg.tar.zst

and appropriate metadata/checksums.

The GitHub Actions workflow must:

1. Build and validate the kernel packages.
2. Generate checksums and relevant build metadata.
3. Create a GitHub Release for that specific successful compilation.
4. Upload the resulting `.pkg.tar.zst` packages to that GitHub Release as release assets.
5. Upload the corresponding checksums and useful metadata/log summaries as release assets where appropriate.
6. Also retain the packages as GitHub Actions workflow artifacts when useful for debugging and CI inspection.

Every compilation must therefore have a permanent, identifiable GitHub Release associated with it.

The release must clearly identify:

- the EnigmarsOS kernel version;
- upstream Linux/Arch kernel version;
- BORE version or commit;
- EnigmarsOS kernel revision;
- Git commit used for the build;
- whether the build was scheduled or manually triggered.

Use a consistent release/tag naming scheme and document it.

Do not create a GitHub Release for a failed build.

Do not publish packages until all required validation stages have succeeded.

For manual builds, the workflow should still create a GitHub Release by default, unless an explicit manual input such as `publish=false` is provided. If `publish=false` is supported, clearly document that behaviour and ensure the workflow still uploads the build as a workflow artifact.

Use the official GitHub Actions mechanism/API for creating releases rather than browser automation.

---

# 17. Package Repository Integration

Design the system so the resulting packages can eventually be published to an EnigmarsOS package repository.

The repository should support:

linux-enigmarsos
linux-enigmarsos-headers

being installed through:

pacman

Do not require users to manually extract package files.

The package repository integration can initially be implemented as a separate publishing stage.

---

# 18. ISO Integration

The eventual EnigmarsOS ISO build must be able to replace:

linux
linux-headers

with:

linux-enigmarsos
linux-enigmarsos-headers

The kernel package should therefore behave like a normal Arch kernel package.

Do not hard-code the kernel into the ISO.

Treat it as a package dependency.

---

# 19. Fallback Kernel

Initially, strongly consider keeping the standard Arch Linux kernel available as a fallback.

The final EnigmarsOS installation should ideally allow users to boot:

EnigmarsOS
    → linux-enigmarsos

EnigmarsOS (Fallback)
    → standard Arch linux

or otherwise provide a straightforward method of installing/booting the standard kernel.

Do not make EnigmarsOS impossible to recover if an EnigmarsOS-specific kernel regression occurs.

---

# 20. Validation

The GitHub Actions workflow must perform automated validation after compilation.

At minimum verify:

- package files exist;
- package metadata is valid;
- kernel image exists;
- initramfs generation succeeds;
- modules exist;
- headers package exists;
- BORE-related configuration is enabled;
- kernel release string identifies EnigmarsOS;
- expected configuration options are present;
- package dependencies are sane.

If feasible, boot the resulting kernel inside QEMU and perform basic automated checks.

Do not claim hardware compatibility merely because a kernel compiles.

---

# 21. BORE Verification

Add a reproducible verification step which proves that the resulting kernel actually contains the intended BORE modifications.

Do not rely solely on:

uname -r

because that only proves the kernel version/name.

Verify the relevant kernel configuration and/or scheduler implementation.

The CI logs should clearly report something like:

Kernel: 6.x.y
EnigmarsOS kernel: enabled
BORE: enabled
Configuration validation: PASS

---

# 22. Security and Supply Chain

Treat the kernel build as security-sensitive infrastructure.

Pin or verify:

- Arch source references;
- BORE source/patch references;
- downloaded archives;
- Git commits where appropriate.

Do not pipe arbitrary remote shell scripts directly into:

bash

without verification.

Use checksums/signatures where available.

Do not store secrets in the repository.

Use GitHub Actions secrets for credentials required to publish packages.

---

# 23. Licensing

Linux kernel licensing must be respected.

BORE's licensing must also be respected.

Before publishing anything, inspect the licenses of:

- Linux;
- Arch packaging materials;
- BORE;
- any additional patches;
- any scripts or third-party sources included in the repository.

Include appropriate license notices and attribution.

Do not assume that because something is publicly available on GitHub it can be redistributed without complying with its licence.

---

# 24. Documentation

Create a comprehensive `README.md` explaining:

- what `linux-enigmarsos` is;
- why EnigmarsOS uses BORE;
- which upstream kernel it tracks;
- which BORE version is used;
- how it differs from Arch's kernel;
- how it is built;
- how GitHub Actions works;
- how often automatic builds occur;
- how to manually trigger a build;
- how packages are published;
- how to recover using the standard Arch kernel.

Also create `BUILDING.md` documenting how a developer can reproduce the build locally if necessary.

---

# 25. Local Development

Although production compilation happens in GitHub Actions, provide a documented local build path.

A developer should be able to run something conceptually similar to:

./scripts/prepare-build.sh
makepkg -s

or another clean command determined by the implementation.

Local building is for:

- debugging;
- testing patches;
- developing configuration changes;
- emergency releases.

It is NOT the normal release mechanism.

---

# 26. Versioning

Design a sensible versioning scheme that clearly relates:

Upstream Linux version
+
EnigmarsOS kernel revision
+
BORE revision

Avoid unnecessarily changing the upstream kernel version.

Document the exact relationship between package version, upstream kernel version, and EnigmarsOS changes.

---

# 27. Failure Behaviour

The system must prefer failing loudly over producing a questionable kernel.

Examples:

BORE patch fails
→ FAIL

Kernel configuration fails
→ FAIL

Expected BORE configuration missing
→ FAIL

Kernel compilation fails
→ FAIL

Package validation fails
→ FAIL

QEMU sanity test fails
→ FAIL

A failed build must NEVER publish a release package.

---

# 28. Do Not Overengineer

This project should be maintainable by one independent developer.

Do not introduce:

- Kubernetes;
- complex microservices;
- unnecessary databases;
- complicated orchestration;
- dozens of external services;
- an elaborate custom build system.

Prefer:

Git repository
+
PKGBUILD
+
patches
+
configuration
+
scripts
+
GitHub Actions

Keep the system boring, transparent and reproducible.

---

# 29. Expected Deliverables

At the end of the task, produce a complete working repository containing:

linux-enigmarsos/
├── PKGBUILD
├── config/
├── patches/
├── scripts/
├── .github/workflows/build.yml
├── README.md
├── BUILDING.md
├── LICENSE
└── SECURITY.md

The repository must be capable of:

1. Obtaining the appropriate Arch Linux kernel sources/package.
2. Applying BORE.
3. Applying EnigmarsOS kernel configuration.
4. Building `linux-enigmarsos`.
5. Building `linux-enigmarsos-headers`.
6. Validating the resulting packages.
7. Running automatically every fortnight through GitHub Actions.
8. Running manually through `workflow_dispatch`.
9. Uploading successful packages as GitHub Actions artifacts.
10. Being extended later to publish packages to the EnigmarsOS package repository.
11. Being integrated into the EnigmarsOS ISO build pipeline.

---

# 30. Final Engineering Principle

The final architecture should follow this philosophy:

                UPSTREAM ARCH
                     │
                     ▼
             Arch Linux Kernel
                     │
                     ├───────────────┐
                     │               │
                     ▼               ▼
                  BORE          EnigmarsOS
                  Patch           Config
                     │               │
                     └───────┬───────┘
                             ▼
                    linux-enigmarsos
                             │
                    GitHub Actions
                    ┌────────┴────────┐
                    │                 │
                 Fortnightly       Manual
                    │                 │
                    └────────┬────────┘
                             ▼
                       Build + Test
                             │
                       ┌─────┴─────┐
                       │           │
                     FAIL        PASS
                       │           │
                     STOP          ▼
                              Publish Artifact
                                    │
                                    ▼
                           EnigmarsOS Repository
                                    │
                                    ▼
                              EnigmarsOS ISO

The most important requirement is that **the developer should not have to manually compile the kernel for routine releases**.

The Git repository should contain everything required to reproduce the kernel, while GitHub Actions performs the expensive compilation on the fortnightly schedule or whenever a developer manually triggers it.

Before implementing anything, inspect the current Arch Linux kernel packaging structure and the current BORE implementation, verify compatibility, and explain any compatibility or maintenance risks you discover.

Do not fabricate package versions, patch versions, configuration options, or upstream compatibility.

When finished, provide:

1. The complete repository structure.
2. Every file that needs to be created or modified.
3. Complete contents of each important file.
4. Exact GitHub Actions configuration.
5. Exact commands for initial setup.
6. Exact commands for testing locally.
7. Explanation of how fortnightly builds work.
8. Explanation of how manual builds work.
9. Explanation of how future Arch kernel updates are incorporated.
10. A maintenance guide for the EnigmarsOS developer.

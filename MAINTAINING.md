# Maintaining linux-enigmarsos

This project is meant to be run by one developer. The loop is small.

```
Arch publishes a new linux-lts
        ↓
./scripts/status.sh                  # notice it
        ↓
./scripts/update-arch-kernel.sh      # pkgver, checksums, config, 000*.patch
        ↓
./scripts/update-bore.sh             # matching BORE patch, or FAIL
        ↓
review the git diff
        ↓
commit, then wait for Wednesday or run it by hand
        (Actions → Build linux-enigmarsos-lts → Run workflow)
        ↓
CI compiles, tests, updates the `lts` GitHub Release
        (packages + linux-enigmarsos-lts.db — pacman mirror)
        ↓
ISO / installed systems: pacman -Sy linux-enigmarsos-lts
        Server = …/releases/download/lts
```

## Weekly (or whenever you open the laptop)

```bash
./scripts/status.sh
```

`IN SYNC` means do nothing. `BEHIND` means Arch moved.
`BORE MISMATCH` means the pinned patch was written for another series.

## Incorporating an Arch kernel update

1. `./scripts/update-arch-kernel.sh`
   - Rewrites `pkgver`, `_arch_pkgrel`, checksums.
   - Replaces `config/config.x86_64`.
   - Refreshes `keys/pgp`.
   - Leaves `pkgrel` and the BORE pin alone.
2. `./scripts/update-bore.sh`
   - Picks a firelzrd patch for the new series.
   - Overwrites `patches/bore.patch` and `patches/bore.meta`.
   - Updates BORE checksums in `PKGBUILD`.
   - Exits non-zero if nothing matches. **Stop there.**
3. Update `config/CONFIG_CHANGES.md` if the Arch baseline version
   listed at the top is now wrong. Do not copy new hardware options
   into the EnigmarsOS fragment "just in case".
4. If this is the same `pkgver` as before (Arch only bumped their
   `pkgrel` / config), bump our `pkgrel`.
5. `git diff` — read the BORE patch header and the PKGBUILD version
   block. If the patch file grew a lot or touches new subsystems,
   read those hunks.
6. Commit to `lts`. Trigger **Build linux-enigmarsos-lts** by hand,
   or wait for the Wednesday schedule (04:00 UTC).

Do not rebase BORE by hand. Do not delete a hunk to make `patch`
succeed. A failed apply is the correct answer.

## Incorporating a BORE-only update

```bash
./scripts/update-bore.sh           # or: ./scripts/update-bore.sh 6.8.1
# bump pkgrel in PKGBUILD
git diff patches/bore.patch
```

Then compile in CI.

## If the Wednesday build fails

1. Open the failed run. The first interesting line is usually
   `patch … did not apply cleanly` or a missing `CONFIG_SCHED_BORE`.
2. If Arch moved and we did not, run the update scripts, commit to
   `lts`, and run the workflow again.
3. If BORE no longer applies, leave the last good `lts` release up and
   wait for an upstream BORE patch. Do not ship
   `linux-enigmarsos-lts` without BORE.
4. QEMU failures: download the artefacts, run `./scripts/qemu-smoke.sh`
   locally, and read the serial log. A hang usually means the kernel
   image is not booting on `ttyS0` (config regression), not a flaky
   test.

## Changing the schedule

Edit `.github/workflows/build-lts.yml`:

```yaml
schedule:
  - cron: '0 4 * * 3'
```

Examples:

- weekly Mondays 04:00 UTC: `0 4 * * 1`
- twice a month: `0 4 1,15 * *`

The file must also exist on `main` (schedules only fire on the default
branch) and checks out `lts`, so mirror schedule edits to both
branches.

## Changing the container pin

```bash
docker pull archlinux:base-devel
docker inspect --format='{{index .RepoDigests 0}}' archlinux:base-devel
```

Put the `repo@sha256:…` value in `env.ARCH_IMAGE`. Rebuild once by
hand before trusting a scheduled run.

## ISO and fallback

See [`iso/README.md`](iso/README.md). The ISO installs
`linux-enigmarsos-lts` (and can carry `linux-enigmarsos` from `main`).
Never hard-code a vmlinuz path.

## What not to add

- A full kernel tree
- CachyOS "sauce", BMQ, or other scheduler stacks
- `-O3`, LTO, or `-march=native` without numbers
- Kubernetes, extra databases, or a custom build system
- Auto-commits from CI that rewrite `PKGBUILD` onto `lts`

Keep the repository boring: packaging + patches + one fragment +
one workflow (scheduled LTS).

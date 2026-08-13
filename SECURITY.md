# Security

`linux-enigmarsos` is treated as security-sensitive infrastructure. A
bad kernel package is worse than no kernel package.

## What we verify

| Input | How |
| --- | --- |
| Linux tarball | SHA-256 + BLAKE2 from Arch's PKGBUILD; detached signature from kernel.org (Linus / Greg KH) |
| Arch patch | SHA-256 + BLAKE2; detached signature from the Arch kernel packager |
| BORE patch | SHA-256 recorded in `patches/bore.meta` and `PKGBUILD`; `prepare-build.sh` re-checks it |
| Arch config | BLAKE2 recorded in `PKGBUILD` (`b2sums_x86_64`) |
| EnigmarsOS fragment | BLAKE2 + SHA-256 in `PKGBUILD` |
| Container image | digest pin in `.github/workflows/build.yml` |

`patch` is invoked with `--fuzz=0`. A context mismatch fails the build
instead of producing a silently wrong scheduler.

## What we do not do

- Pipe remote scripts into `bash`.
- Fetch an unsigned "latest BORE" URL at compile time.
- Skip the BORE patch to keep a green CI.
- Publish a GitHub Release from a failed job.
- Store tokens, signing keys, or `~/.makepkg.conf` secrets in git.

## Secrets

GitHub Actions uses the automatically provided `GITHUB_TOKEN` to create
releases. That is enough for this repository.

If a future job publishes to an EnigmarsOS pacman host, put those
credentials in GitHub Actions secrets (`ENIGMARSOS_REPO_SSH_KEY` or
similar). Never commit them. The stub `scripts/publish-repo.sh` only
writes a local directory.

## Reporting a kernel vulnerability

- Upstream Linux: <https://docs.kernel.org/process/security-bugs.html>
- Arch packaging: <https://security.archlinux.org/>
- BORE-specific: <https://github.com/firelzrd/bore-scheduler/issues>
- EnigmarsOS packaging mistakes in this repo: open a private security
  advisory on the GitHub repository if the issue is in our scripts or
  in how we apply the patch. Do not file a public issue for an
  unpatched kernel bug.

When Arch publishes a security `linux` update, run
`./scripts/update-arch-kernel.sh` the same day if you can, then
`./scripts/update-bore.sh`, then trigger the workflow.

## Supply-chain notes

- The Arch packaging clone prefers `gitlab.archlinux.org` and falls
  back to the `ClangBuiltLinux/linux_pkgbuild` mirror. Compare
  checksums against `archlinux.org/packages/core/x86_64/linux/` if a
  mirror looks stale.
- BORE's git history is unsigned. We pin a commit and a file hash.
  Review the diff when `update-bore.sh` moves the pin.
- GitHub Actions third-party actions are limited to official
  `actions/*` plus the Arch container. Prefer digest pins when
  updating the workflow.
- `ccache` is keyed on package version + BORE commit + config hashes.
  A mismatch starts a cold cache. Do not widen `restore-keys` in a way
  that can reuse objects from a different patch set.

## Reproducibility

CI sets `SOURCE_DATE_EPOCH` from the git commit timestamp and
`KBUILD_BUILD_HOST=enigmarsos`. Two compiles of the same commit in the
same container digest should be comparable. They will not match a
laptop build with a different toolchain.

# EnigmarsOS package repository (later)

GitHub Releases are the current distribution channel. A proper pacman
repository is a second publishing stage, not part of the compile job.

## Layout

```
/srv/repo/linux-enigmarsos/os/x86_64/
    linux-enigmarsos-7.1.8.arch1-1-x86_64.pkg.tar.zst
    linux-enigmarsos-headers-7.1.8.arch1-1-x86_64.pkg.tar.zst
    linux-enigmarsos.db.tar.gz
    linux-enigmarsos.files.tar.gz
```

Build that directory from CI artefacts:

```bash
./scripts/publish-repo.sh /srv/repo/linux-enigmarsos/os/x86_64 /path/to/out
```

Serve it over HTTPS. Then ship [`enigmarsos.example.conf`](enigmarsos.example.conf)
as `/etc/pacman.d/linux-enigmarsos.conf` and `Include` it from
`pacman.conf`.

## Signing (when you are ready)

`publish-repo.sh` does not sign. When EnigmarsOS has a packaging key:

1. Store the private key in a GitHub Actions secret.
2. `gpg --detach-sign` each package.
3. Change `SigLevel` from `Optional TrustAll` to `Required`.
4. Ship the public key in the ISO.

Until then, users installing from GitHub Releases should read
`SHA256SUMS`.

## CI hook

Do **not** upload to the repo from the compile job until validation
has passed. The compile workflow already refuses to create a GitHub
Release on failure. A future `publish-repo` job should `needs: build`
and only run when `publish=true`.

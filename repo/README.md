# EnigmarsOS kernel pacman repository (GitHub Releases)

The **$0 mirror** is the Latest GitHub Release of this repo.

Pacman does not need a directory listing. It only GETs:

- `linux-enigmarsos.db` (or `.db.tar.gz`)
- then the `.pkg.tar.zst` files named in that database

GitHub serves those via:

```text
https://github.com/RishiSpace/linux-enigmarsos/releases/latest/download/<filename>
```

## Client snippet

See [`enigmarsos.example.conf`](enigmarsos.example.conf):

```ini
[linux-enigmarsos]
SigLevel = Optional TrustAll
Server = https://github.com/RishiSpace/linux-enigmarsos/releases/latest/download
```

```bash
sudo pacman -Sy linux-enigmarsos linux-enigmarsos-headers
```

## What each Latest release must contain

| Asset | Why |
| --- | --- |
| `linux-enigmarsos-<ver>-x86_64.pkg.tar.zst` | Kernel package |
| `linux-enigmarsos-headers-<ver>-x86_64.pkg.tar.zst` | Headers |
| `linux-enigmarsos.db` | **Regular file** copy of the db (GitHub cannot serve a symlink) |
| `linux-enigmarsos.db.tar.gz` | Same db, archived |
| `linux-enigmarsos.files` / `.files.tar.gz` | File list (`pacman -F`) |
| `SHA256SUMS` | Verification |

Build that set from compiled packages:

```bash
./scripts/publish-repo.sh /tmp/eos-kernel-repo .
# or: ./scripts/publish-repo.sh /tmp/eos-kernel-repo /path/to/out
```

CI runs the same script and attaches the files when it creates a Release.

## Local / ISO file:// repo

ISO builds can download Latest into a folder and use `file://`:

```bash
mkdir -p /tmp/eos-kernel-repo
cd /tmp/eos-kernel-repo
base=https://github.com/RishiSpace/linux-enigmarsos/releases/latest/download
curl -fL -O "$base/linux-enigmarsos.db"
# or download both .pkg.tar.zst and run publish-repo.sh
```

`mkarchiso` then uses `Server = file:///tmp/eos-kernel-repo`.

## Signing (later)

`publish-repo.sh` does not sign. When EnigmarsOS has a packaging key:

1. Store the private key in a GitHub Actions secret.
2. `gpg --detach-sign` each package.
3. Change `SigLevel` from `Optional TrustAll` to `Required`.
4. Ship the public key in the ISO (`enigmarsos-keyring`).

Until then, verify `SHA256SUMS`.

## CI

The compile workflow only publishes after validation. The release step
uploads packages **and** the materialized db files. Do not mark a
release Latest unless those db assets are present — otherwise
`pacman -Sy` 404s on `linux-enigmarsos.db`.

export MAKEFLAGS="-j2"
export PKGDEST="$PWD/out"
mkdir -p "$PKGDEST"

# free RAM before starting: close browsers / other heavy apps
gpg --import keys/pgp/*.asc

./scripts/status.sh
./scripts/update-arch-kernel.sh
./scripts/update-bore.sh
./scripts/prepare-build.sh

makepkg -sf --noconfirm --needed

./scripts/verify-build.sh "$PKGDEST"
ls -lh "$PKGDEST"/linux-enigmarsos-*.pkg.tar.zst

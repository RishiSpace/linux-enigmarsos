# Maintainer: EnigmarsOS
# Contributor: Jan Alexander Steffens (heftig) <heftig@archlinux.org>
#
# Derived from the official Arch Linux `linux` PKGBUILD (0BSD).
# Tracked Arch package: linux 7.1.8.arch1-3
#
# This is not a kernel fork. The tree is:
#   vanilla Linux 7.1.8 + Arch patch + BORE 6.8.0 + EnigmarsOS config fragment

pkgbase=linux-enigmarsos
pkgver=7.1.8.arch1
pkgrel=2
pkgdesc='EnigmarsOS Linux'
url='https://github.com/enigmarsos/linux-enigmarsos'
arch=(x86_64)
license=(GPL-2.0-only)
makedepends=(
  bc
  binutils
  cpio
  gettext
  glibc
  libelf
  libgcc
  openssl
  pahole
  perl
  python
  rust
  rust-bindgen
  rust-src
  tar
  xxhash
  xz
  zlib
  zstd
)
options=(
  !debug
  !strip
)

# Arch linux package this PKGBUILD was last synchronized against.
_arch_pkgrel=3
_srcname=linux-${pkgver%.*}
_srctag=v${pkgver%.*}-${pkgver##*.}
_arch_linux_url='https://github.com/archlinux/linux'

# BORE pin. Keep in sync with patches/bore.meta.
_bore_version=6.8.0
_bore_commit=6a52aac2deab3faebcae97a34bb3eec4b3c2967e
_bore_designed_for=7.1.5

source=(
  https://cdn.kernel.org/pub/linux/kernel/v${pkgver%%.*}.x/${_srcname}.tar.{xz,sign}
  $_arch_linux_url/releases/download/$_srctag/linux-$_srctag.patch.zst{,.sig}
  bore.patch
  enigmarsos.config
)
source_x86_64=(
  config.x86_64
)
validpgpkeys=(
  ABAF11C65A2970B130ABE3C479BE3E4300411886  # Linus Torvalds
  647F28654894E3BD457199BE38DBBDC86092693E  # Greg Kroah-Hartman
  83BC8889351B5DEBBB68416EB8AC08600F108CDF  # Jan Alexander Steffens (heftig)
)
b2sums=('84b59e5572d91f5ea1bb603aa7691851bd9549e1bf18a6bec8e27eb8a6e2de2e33da2ad3e3aad501c793e9756e70245a16545e76b65a44ee52b33ccf5c3dd8e7'
        'SKIP'
        '308952977c15ac3ad976ff1d99d0d186814d4b03e1c8512fc3a4c0ac1ecce3f74be8f3900a7fd286492d4f930bedc089674bf713a278fa80c35413e0e6339f97'
        'SKIP'
        '2ab3e6d9079e4889bafdc7dd209d298b35022aa56098696b7c5d5f39adacc8e122b7d4c73666193df0dd5a721f8ef5d8c6e8c132ad63c01439753849d32e9506'
        '601173bc543df5605e0f6babecc5182bd5747de25d126c4b38907b51e7b572d9320c2dd09766e1b7da1bb7f2c76ee1a166aea33cea44929c35ee2ba8a02b3aab')
b2sums_x86_64=('b10d80423aa3eb65e2046bf5b1998f9a7bdbc97494c6881881f50ffcdb5fe2e242782f59dbb6402cd77ce64b988dbf295fd9fa54f20180c76fbe88b82e1dbc9d')

# https://www.kernel.org/pub/linux/kernel/v7.x/sha256sums.asc
sha256sums=('ff01dcb449279d5b4cfccdb01fee639cf5ff1803f1749a77844dd33915422c49'
            'SKIP'
            '351cfb04db323bf5dd55ae8ce626650d20ba61441d202cadd8e198c6b9ef8f36'
            'SKIP'
            'ec1edcf30028d605edafe3a7fc634870f41e5cac7a66ecdd1198e2ac4ef6a634'
            'b6d8fccf612825da9eff2532bfb33761922f121eaab2075643c20a58ce5a1318')

export KBUILD_BUILD_HOST=enigmarsos
export KBUILD_BUILD_USER=$pkgbase
export KBUILD_BUILD_TIMESTAMP="$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})"

_die() {
  printf '==> ERROR: %s\n' "$*" >&2
  exit 1
}

_require_config() {
  local opt="$1" expected="$2" got
  got=$(scripts/config --file .config -s "$opt" || true)
  if [[ "$got" != "$expected" ]]; then
    _die "required option $opt is '${got:-<unset>}', expected '$expected'"
  fi
}

prepare() {
  cd $_srcname

  echo "Setting version..."
  # Arch's patch sets EXTRAVERSION=-arch1. Clear it so uname -r looks like
  # other distros (7.1.8-2-enigmarsos), not 7.1.8-arch1-2-enigmarsos.
  # Keep upstream version + pkgrel so /usr/lib/modules/* stays unique.
  sed -i 's/^EXTRAVERSION =.*/EXTRAVERSION =/' Makefile
  echo "-$pkgrel" > localversion.10-pkgrel
  echo "-enigmarsos" > localversion.20-pkgname

  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    src="${src%.zst}"
    [[ $src = *.patch ]] || continue
    echo "Applying patch $src..."
    # --fuzz=0: a context mismatch is a hard failure. Never skip BORE.
    patch -Np1 --fuzz=0 --forward < "../$src" \
      || _die "patch $src did not apply cleanly; refusing to build an unpatched kernel"
  done

  [[ -f kernel/sched/bore.c ]] \
    || _die "kernel/sched/bore.c missing after patching; BORE did not apply"
  grep -q "SCHED_BORE_VERSION[[:space:]]\\+\"$_bore_version\"" include/linux/sched/bore.h \
    || _die "BORE version string $_bore_version not found in include/linux/sched/bore.h"

  echo "Setting config..."
  cp ../config.$CARCH .config

  echo "Applying EnigmarsOS configuration fragment..."
  scripts/config --file .config --enable SCHED_BORE
  scripts/config --file .config --set-val MIN_BASE_SLICE_NS 2000000

  make olddefconfig
  diff -u ../config.$CARCH .config || :

  echo "Validating EnigmarsOS configuration..."
  _require_config SCHED_BORE y
  _require_config MIN_BASE_SLICE_NS 2000000
  _require_config IKCONFIG y
  _require_config IKCONFIG_PROC y

  make -s kernelrelease > version
  local krel
  krel=$(<version)
  echo "Prepared $pkgbase version $krel"
  [[ $krel == *enigmarsos* ]] \
    || _die "kernel release '$krel' does not identify EnigmarsOS"
}

build() {
  cd $_srcname
  make all
  make -C tools/bpf/bpftool vmlinux.h feature-clang-bpf-co-re=1
}

_package() {
  pkgdesc="The $pkgdesc kernel and modules (BORE scheduler)"
  depends=(
    coreutils
    initramfs
    kmod
  )
  optdepends=(
    "$pkgbase-headers: headers and scripts for building modules"
    'linux-firmware: firmware images needed for some devices'
    'scx-scheds: to use sched-ext schedulers'
    'wireless-regdb: to set the correct wireless channels of your country'
    'linux: official Arch kernel used as the EnigmarsOS fallback'
  )
  provides=(
    KSMBD-MODULE
    NTSYNC-MODULE
    VIRTUALBOX-GUEST-MODULES
    WIREGUARD-MODULE
  )
  # Do not conflict with or replace `linux`. The Arch kernel stays
  # installable as the fallback boot entry.

  cd $_srcname
  local modulesdir="$pkgdir/usr/lib/modules/$(<version)"

  echo "Installing boot image..."
  # systemd expects to find the kernel here to allow hibernation
  # https://github.com/systemd/systemd/commit/edda44605f06a41fb86b7ab8128dcf99161d2344
  install -Dm644 "$(make -s image_name)" "$modulesdir/vmlinuz"

  # Used by mkinitcpio to name the kernel
  echo "$pkgbase" | install -Dm644 /dev/stdin "$modulesdir/pkgbase"

  echo "Installing modules..."
  ZSTD_CLEVEL=19 make INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 \
    DEPMOD=/doesnt/exist modules_install  # Suppress depmod

  # remove build link
  rm "$modulesdir"/build
}

_package-headers() {
  pkgdesc="Headers and scripts for building modules for the $pkgdesc kernel"
  depends=(
    binutils
    glibc
    libelf
    libgcc
    openssl
    pahole
    xxhash
    zlib
    zstd
  )
  provides=(LINUX-HEADERS)

  cd $_srcname
  local builddir="$pkgdir/usr/lib/modules/$(<version)/build"

  local karch
  case $CARCH in
    x86_64) karch=x86 ;;
    *) echo "Unknown CARCH $CARCH"; exit 1 ;;
  esac

  echo "Installing build files..."
  install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map \
    localversion.* version vmlinux tools/bpf/bpftool/vmlinux.h
  install -Dt "$builddir/kernel" -m644 kernel/Makefile
  install -Dt "$builddir/arch/$karch" -m644 arch/$karch/Makefile
  cp -t "$builddir" -a scripts
  ln -srt "$builddir" "$builddir/scripts/gdb/vmlinux-gdb.py"

  if [[ $(scripts/config -s CONFIG_HAVE_STACK_VALIDATION) = y ]]; then
    install -Dt "$builddir/tools/objtool" tools/objtool/objtool
  fi

  if [[ $(scripts/config -s CONFIG_DEBUG_INFO_BTF_MODULES) = y ]]; then
    install -Dt "$builddir/tools/bpf/resolve_btfids" tools/bpf/resolve_btfids/resolve_btfids
  fi

  echo "Installing headers..."
  cp -t "$builddir" -a include
  cp -t "$builddir/arch/$karch" -a arch/$karch/include
  install -Dt "$builddir/arch/$karch/kernel" -m644 arch/$karch/kernel/asm-offsets.s

  install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
  install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h

  # https://bugs.archlinux.org/task/13146
  install -Dt "$builddir/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h

  # https://bugs.archlinux.org/task/20402
  install -Dt "$builddir/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
  install -Dt "$builddir/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
  install -Dt "$builddir/drivers/media/tuners" -m644 drivers/media/tuners/*.h

  # https://bugs.archlinux.org/task/71392
  install -Dt "$builddir/drivers/iio/common/hid-sensors" -m644 drivers/iio/common/hid-sensors/*.h

  echo "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;

  if [[ $(scripts/config -s CONFIG_RUST) = y ]]; then
    echo "Installing Rust files..."
    install -Dt "$builddir/rust" -m644 rust/*.rmeta
    install -Dt "$builddir/rust" rust/*.so
  fi

  echo "Installing unstripped VDSO..."
  make INSTALL_MOD_PATH="$pkgdir/usr" vdso_install \
    link=  # Suppress build-id symlinks

  echo "Removing unneeded architectures..."
  local arch
  for arch in "$builddir"/arch/*/; do
    [[ $arch = */$karch/ ]] && continue
    echo "Removing $(basename "$arch")"
    rm -r "$arch"
  done

  echo "Removing documentation..."
  rm -r "$builddir/Documentation"

  echo "Removing broken symlinks..."
  find -L "$builddir" -type l -printf 'Removing %P\n' -delete

  echo "Removing loose objects..."
  find "$builddir" -type f -name '*.o' -printf 'Removing %P\n' -delete

  echo "Stripping build tools..."
  local file
  while read -rd '' file; do
    case "$(file -Sib "$file")" in
      application/x-sharedlib\;*)      # Libraries (.so)
        strip -v $STRIP_SHARED "$file" ;;
      application/x-archive\;*)        # Libraries (.a)
        strip -v $STRIP_STATIC "$file" ;;
      application/x-executable\;*)     # Binaries
        strip -v $STRIP_BINARIES "$file" ;;
      application/x-pie-executable\;*) # Relocatable binaries
        strip -v $STRIP_SHARED "$file" ;;
    esac
  done < <(find "$builddir" -type f -perm -u+x ! -name vmlinux -print0)

  echo "Stripping vmlinux..."
  strip -v $STRIP_STATIC "$builddir/vmlinux"

  echo "Adding symlink..."
  mkdir -p "$pkgdir/usr/src"
  ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"
}

pkgname=(
  "$pkgbase"
  "$pkgbase-headers"
)
for _p in "${pkgname[@]}"; do
  eval "package_$_p() {
    $(declare -f "_package${_p#$pkgbase}")
    _package${_p#$pkgbase}
  }"
done

# vim:set ts=8 sts=2 sw=2 et:

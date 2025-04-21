#!/bin/sh
set -o errexit
set -o nounset

# shellcheck source=./src/shared.sh
. /opt/scripts/shared.sh
check_env_var "${ANDROID_ABI:-}" "ANDROID_ABI"
check_env_var "${ANDROID_API_LEVEL:-}" "ANDROID_API_LEVEL"
check_env_var "${ANDROID_NDK_ROOT:-}" "ANDROID_NDK_ROOT"
check_env_var "${ANDROID_TOOLCHAIN:-}" "ANDROID_TOOLCHAIN"

export AR="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
export AS="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-as"
export CC="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/${ANDROID_TOOLCHAIN}${ANDROID_API_LEVEL}-clang"
export CXX="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/${ANDROID_TOOLCHAIN}${ANDROID_API_LEVEL}-clang++"
export LD="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/ld"
export RANLIB="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib"
export STRIP="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
export CFLAGS="-DHAVE_SYS_FILE_H=1"

setup_env() {
    tmp_dir=$(mktemp --directory)
    cd "${tmp_dir}"
    tar --extract --file /opt/vendor/libuuid.tar.gz
    cd libuuid-*
}

configure() {
    ./configure \
        --host="${ANDROID_TOOLCHAIN}" \
        --with-pic \
        --disable-shared \
        --enable-static \
        --prefix="/usr/lib/libuuid/android-${ANDROID_API_LEVEL}-${ANDROID_ABI}"
    autoreconf --install --force
}

build_and_install() {
    make
    make install
}

main() {
    setup_env
    configure
    build_and_install
}

main

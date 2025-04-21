#!/bin/sh
set -o errexit
set -o nounset

ANDROID_ABI=$(cat /opt/config/ANDROID_ABI)
ANDROID_API_LEVEL=$(cat /opt/config/ANDROID_API_LEVEL)
ANDROID_NDK_ROOT=$(cat /opt/config/ANDROID_NDK_ROOT)
ANDROID_TOOLCHAIN=$(cat /opt/config/ANDROID_TOOLCHAIN)
CARGO_TOOLCHAIN=$(cat /opt/config/CARGO_TOOLCHAIN)
SYSROOT_TOOLCHAIN=$(cat /opt/config/SYSROOT_TOOLCHAIN)

export PATH="${PATH}:/usr/lib/android-sdk/cmake/3.31.6/bin"
export PATH="${PATH}:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin"
export PATH="${PATH}:${HOME}/.cargo/bin"

ndk_sysroot="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/sysroot"

# needed for correct linking (ex. unable to find library -llog)
toolchain_formatted=$(echo "${CARGO_TOOLCHAIN}" | tr '[:lower:]' '[:upper:]' | sed 's/-/_/g')
export "CARGO_TARGET_${toolchain_formatted}_AR"="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/${ANDROID_TOOLCHAIN}-ar"
export "CARGO_TARGET_${toolchain_formatted}_LINKER"="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/${ANDROID_TOOLCHAIN}${ANDROID_API_LEVEL}-clang"
export "CARGO_TARGET_${toolchain_formatted}_RUSTFLAGS"="-C linker=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin/${ANDROID_TOOLCHAIN}${ANDROID_API_LEVEL}-clang"

# required for building aws-lc-sys
export ANDROID_NDK_ROOT
# aws-lc-sys cannot discover pthread without these options
export AWS_LC_SYS_STATIC=1
export AWS_LC_SYS_CFLAGS="\
-B${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${SYSROOT_TOOLCHAIN}/${ANDROID_API_LEVEL} \
--sysroot=${ndk_sysroot} \
-I${ndk_sysroot}/usr/include"

create_backup_file() {
    backup_file="${1}.bak"
    if [ -e "${backup_file}" ]; then
        echo "fatal: cannot create backup: ${backup_file}" >&2
        exit 1
    fi
    cp "${1}" "${backup_file}"
}

patch_cmakelists() {
    # not happy with this solution but it should be convenient for the enduser
    cmakefile_name="CMakeLists.txt"
    if grep --quiet --extended-regexp '^set \(TASK_LIBRARIES dl pthread\)$' "${cmakefile_name}"; then
        create_backup_file "${cmakefile_name}"
        sed --in-place '/^set (TASK_LIBRARIES dl pthread)$/s/^/#/' "${cmakefile_name}"
    fi
}

configuration() {
    cmake \
        -S . \
        -B build \
        -G Ninja \
        -DANDROID_ABI="${ANDROID_ABI}" \
        -DANDROID_PLATFORM="${ANDROID_API_LEVEL}" \
        -DCMAKE_ANDROID_NDK="${ANDROID_NDK_ROOT}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS="-Wno-c++11-narrowing" \
        -DCMAKE_SYSROOT="${ndk_sysroot}" \
        -DCMAKE_SYSTEM_NAME=Android \
        -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake" \
        -DRust_CARGO_TARGET="${CARGO_TOOLCHAIN}" \
        -DUUID_INCLUDE_DIR="/usr/lib/libuuid/android-${ANDROID_API_LEVEL}-${ANDROID_ABI}/include" \
        -DUUID_LIBRARY="/usr/lib/libuuid/android-${ANDROID_API_LEVEL}-${ANDROID_ABI}/lib/libuuid.a" \
        .
}

build() {
    cmake --build build
}

main() {
    patch_cmakelists
    configuration
    build
}

main

#!/bin/sh
set -o errexit
set -o nounset

build_image() {
    image_tag="${1}"
    android_abi="${2}"

    case "${android_abi}" in
        "arm64-v8a")
            android_toolchain="aarch64-linux-android"
            cargo_toolchain="aarch64-linux-android"
            sysroot_toolchain="aarch64-linux-android"
            ;;
        "armeabi-v7a")
            android_toolchain="armv7a-linux-androideabi"
            cargo_toolchain="armv7-linux-androideabi"
            sysroot_toolchain="arm-linux-androideabi"
            ;;
        *)
            echo "fatal: requires argument: arm64-v8a, armeabi-v7a" >&2
            exit 1
    esac

    docker build \
        --build-arg ANDROID_ABI="${android_abi}" \
        --build-arg ANDROID_API_LEVEL="30" \
        --build-arg ANDROID_TOOLCHAIN="${android_toolchain}" \
        --build-arg CARGO_TOOLCHAIN="${cargo_toolchain}" \
        --build-arg CMAKE_VERSION="3.31.6" \
        --build-arg NDK_VERSION="27.2.12479018" \
        --build-arg SYSROOT_TOOLCHAIN="${sysroot_toolchain}" \
        --tag "${image_tag}" \
        .
}

run_container() {
    image_tag="${1}"
    docker run \
        --rm \
        --volume "${PWD}/taskwarrior:/build" \
        --interactive \
        --tty \
        "${image_tag}"
}

main() {
    android_abi="${1}"
    image_tag="taskwarrior-android-buildenv:${android_abi}"
    build_image "${image_tag}" "${android_abi}"
    run_container "${image_tag}"
}

main "${1:-}"

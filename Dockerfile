FROM debian:trixie
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# libtool and automake are required for libuuid
# libclang-dev is required for building aws-lc bindings
RUN sed \
    --in-place 's/^Components: main$/& contrib non-free/' \
    /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install \
    --no-install-recommends \
    --assume-yes \
    automake=1:1.17-4 \
    build-essential=12.12 \
    google-android-cmdline-tools-19.0-installer=19.0+1743526702-1 \
    libtool=2.5.4-4 \
    rustup=1.27.1-3 \
    libclang-dev=1:19.0-63 \
    && apt-get clean \
    && rm --recursive --dir /var/lib/apt/lists/* \
    && rustup default stable
ARG CMAKE_VERSION
RUN (yes || true) | sdkmanager --install "cmake;$CMAKE_VERSION"
# ndk version 27 seems to work just fine, albeit 28 does not
ARG NDK_VERSION
RUN (yes || true) | sdkmanager --install "ndk;$NDK_VERSION"
ARG ANDROID_NDK_ROOT="/usr/lib/android-sdk/ndk/${NDK_VERSION}"
RUN mkdir --parents /opt/vendor \
    && wget \
    --progress=dot:giga \
    --output-document /opt/vendor/libuuid.tar.gz \
    "https://sourceforge.net/projects/libuuid/files/libuuid-1.0.3.tar.gz"
ARG ANDROID_ABI
# aws-lc-sys (pthread_atfork) requires api level 21 or above
# pthread_cond_clockwait requires a minimum api level of 30
ARG ANDROID_API_LEVEL
ARG ANDROID_TOOLCHAIN
ARG CARGO_TOOLCHAIN
ARG SYSROOT_TOOLCHAIN
RUN rustup target add "${CARGO_TOOLCHAIN}" \
    && ( \
    [ "${CARGO_TOOLCHAIN}" = "aarch64-linux-android" ] \
    || cargo install --force --locked bindgen-cli \
    )
COPY --chmod=755 ./src/shared.sh /opt/scripts/shared.sh
COPY --chmod=755 ./src/prebuild.sh /opt/scripts/prebuild.sh
RUN /opt/scripts/prebuild.sh
# preserve buildtime config for runtime
RUN mkdir --parents /opt/config \
    && echo "$ANDROID_ABI" > /opt/config/ANDROID_ABI \
    && echo "$ANDROID_API_LEVEL" > /opt/config/ANDROID_API_LEVEL \
    && echo "$ANDROID_NDK_ROOT" > /opt/config/ANDROID_NDK_ROOT \
    && echo "$ANDROID_TOOLCHAIN" > /opt/config/ANDROID_TOOLCHAIN \
    && echo "$CARGO_TOOLCHAIN" > /opt/config/CARGO_TOOLCHAIN \
    && echo "$SYSROOT_TOOLCHAIN" > /opt/config/SYSROOT_TOOLCHAIN
WORKDIR /build
COPY --chmod=755 ./src/entrypoint.sh /opt/scripts/entrypoint.sh
ENTRYPOINT ["/opt/scripts/entrypoint.sh"]

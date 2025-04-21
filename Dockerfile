FROM debian:trixie
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# libtool and automake are required for libuuid
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
    && apt-get clean \
    && rm --recursive --dir /var/lib/apt/lists/* \
    && rustup default stable
ARG CMAKE_VERSION="3.31.6"
RUN (yes || true) | sdkmanager --install "cmake;$CMAKE_VERSION"
# ndk version 27 seems to work just fine, albeit 28 does not
ARG NDK_VERSION="27.2.12479018"
RUN (yes || true) | sdkmanager --install "ndk;$NDK_VERSION"
ARG ANDROID_NDK_ROOT="/usr/lib/android-sdk/ndk/${NDK_VERSION}"
RUN mkdir --parents /opt/vendor \
    && wget \
    --progress=dot:giga \
    --output-document /opt/vendor/libuuid.tar.gz \
    "https://sourceforge.net/projects/libuuid/files/libuuid-1.0.3.tar.gz"
ARG ANDROID_ABI="arm64-v8a"
# aws-lc-sys (pthread_atfork) requires api level 21 or above
# pthread_cond_clockwait requires a minimum api level of 30
ARG ANDROID_API_LEVEL="30"
ARG ANDROID_TOOLCHAIN="aarch64-linux-android"
RUN rustup target add "${ANDROID_TOOLCHAIN}"
COPY --chmod=755 ./src/shared.sh /opt/scripts/shared.sh
COPY --chmod=755 ./src/prebuild.sh /opt/scripts/prebuild.sh
RUN /opt/scripts/prebuild.sh
# preserve buildtime config for runtime
RUN mkdir --parents /opt/config \
    && echo "$ANDROID_NDK_ROOT" > /opt/config/ANDROID_NDK_ROOT \
    && echo "$ANDROID_ABI" > /opt/config/ANDROID_ABI \
    && echo "$ANDROID_API_LEVEL" > /opt/config/ANDROID_API_LEVEL \
    && echo "$ANDROID_TOOLCHAIN" > /opt/config/ANDROID_TOOLCHAIN
WORKDIR /build
COPY --chmod=755 ./src/entrypoint.sh /opt/scripts/entrypoint.sh
ENTRYPOINT ["/opt/scripts/entrypoint.sh"]

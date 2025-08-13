FROM ubuntu:24.04 AS compiler

ARG OSX_SDK_VERSION=15.5
ARG OSX_SDK_BASENAME=MacOSX${OSX_SDK_VERSION}.sdk.tar.bz2
ARG OSX_CROSS_URL=https://github.com/Luiz-Monad/osxcross.git
ARG OSX_CROSS_TARBALLS=tarballs
ARG OSX_CROSS_BRANCH=master
ARG BUILD_CLANG=false

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        llvm clang cmake make ninja-build pkg-config curl xz-utils \
        patch git file python3 python3-pip unzip bzip2 ca-certificates \
        libxml2-dev liblzma-dev libssl-dev zlib1g-dev uuid-dev && \
    rm -rf /var/lib/apt/lists/*

# Clone osxcross source
WORKDIR /build
RUN git clone ${OSX_CROSS_URL} --branch ${OSX_CROSS_BRANCH} --depth 1

# Clone tarballs branch from your fork (shallow)
WORKDIR /build/osxcross
RUN git clone --branch ${OSX_CROSS_TARBALLS} --depth 1 ${OSX_CROSS_URL} tarballs_repo && \
    cp -a tarballs_repo/tarballs/${OSX_SDK_BASENAME}.* tarballs/ && \
    rm -rf tarballs_repo

# Merge split parts into a single SDK tarball
WORKDIR /build/osxcross/tarballs
RUN cat ${OSX_SDK_BASENAME}.part* > ${OSX_SDK_BASENAME} && \
    rm -f ${OSX_SDK_BASENAME}.part*

# Build clang itslf
WORKDIR /build/osxcross
RUN [ "$BUILD_CLANG" = "true" ] && \
    INSTALLPREFIX=/opt/osxcross UNATTENDED=1 ./build_clang.sh || true

# Build osxcross (multi-arch clang)
WORKDIR /build/osxcross
RUN TARGET_DIR=/opt/osxcross UNATTENDED=1 ./build.sh

# Clean
WORKDIR /opt/osxcross
RUN rm -rf /build

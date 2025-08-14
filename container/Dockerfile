FROM ubuntu:24.04 AS base

ARG OSX_SDK_VERSION=15.5
ARG OSX_SDK_BASENAME=MacOSX${OSX_SDK_VERSION}.sdk.tar.bz2
ARG OSX_CROSS_URL=https://github.com/Luiz-Monad/osxcross.git
ARG OSX_CROSS_TARBALLS=tarballs
ARG OSX_CROSS_BRANCH=master
ARG BUILD_CLANG=false
ARG USE_LD64=false

# Install required packages
COPY ./ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources
RUN apt-get update && apt-get install -y --no-install-recommends \
        llvm lld clang cmake make ninja-build pkg-config curl xz-utils \
        patch git file python3 python3-pip unzip bzip2 ca-certificates \
        libxml2-dev liblzma-dev libssl-dev zlib1g-dev uuid-dev \
        && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

FROM base AS tarball

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

FROM tarball AS compiler

# Fix LLD
RUN ln -s $(ls -1 /usr/bin/ld64.lld-* | sort -V | tail -1) /usr/bin/ld64.lld

# Build clang itslf
WORKDIR /build/osxcross
RUN [ "$BUILD_CLANG" = "true" ] && \
    INSTALLPREFIX=/opt/osxcross UNATTENDED=1 ./build_clang.sh || true

# Build osxcross (multi-arch clang)
WORKDIR /build/osxcross
RUN TARGET_DIR=/opt/osxcross UNATTENDED=1 ./build.sh || true

# COPY ./debug.sh ./debug.sh
# RUN --mount=type=secret,id=NGROK_SSH_PUBKEY,env=NGROK_SSH_PUBKEY \
#     --mount=type=secret,id=NGROK_TOKEN,env=NGROK_TOKEN \
#     bash -c ./debug.sh && tail -f /dev/null

# Clean
WORKDIR /opt/osxcross
RUN rm -rf /build

# Final stage - minimal runtime image
FROM base AS final

# Copy the compiled osxcross toolchain from builder stage
COPY --from=compiler /opt/osxcross /opt/osxcross

# Set up environment
ENV PATH="/opt/osxcross/bin:$PATH"
ENV OSXCROSS_ROOT="/opt/osxcross"
WORKDIR /opt/osxcross

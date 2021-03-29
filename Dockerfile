# Golang docker image options
ARG GO_IMAGE=buster
ARG GO_VERSION=1.13.15

# Libtool arguments
ARG LIBTOOL_VERSION=2.4.6

# Mac OS SDK used to osxcross
ARG OSX_SDK=MacOSX10.11.sdk
ARG OSX_SDK_URL=https://github.com/vxcontrol/vxbuild-cross/releases/download/v0.0.0
ARG OSX_SDK_SUM=98cdd56e0f6c1f9e1af25e11dd93d2e7d306a4aa50430a2bc6bc083ac67efbb8

# osxcross arguments
ARG OSX_VERSION_MIN=10.11
ARG OSX_CODENAME=el_capitan
ARG OSX_CROSS_COMMIT=ee54d9fd43b45947ee74c99282b360cd27a8f1cb
ARG OSX_CROSS_REQUIREMENTS=""

# Preparing base part of target image
FROM golang:${GO_VERSION}-${GO_IMAGE} AS base
ARG APT_MIRROR
RUN sed -ri "s/(httpredir|deb).debian.org/${APT_MIRROR:-deb.debian.org}/g" /etc/apt/sources.list \
 && sed -ri "s/(security).debian.org/${APT_MIRROR:-security.debian.org}/g" /etc/apt/sources.list
ENV OSX_CROSS_PATH=/osxcross

# Pulling and checking SDK tarball
FROM base AS osx-sdk
ARG OSX_SDK
ARG OSX_SDK_URL
ARG OSX_SDK_SUM
ADD ${OSX_SDK_URL}/${OSX_SDK}.tar.xz "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"
RUN echo "${OSX_SDK_SUM}" "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz" | sha256sum -c -

# Preparing of osxcross build
FROM base AS osx-cross-base
ARG OSX_CROSS_REQUIREMENTS
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y -q --no-install-recommends \
    clang \
    cmake \
    llvm \
    libc++-dev \
    file \
    patch \
    xz-utils \
    ${OSX_CROSS_REQUIREMENTS} \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Building osxcross
FROM osx-cross-base AS osx-cross
ARG OSX_CROSS_COMMIT
WORKDIR "${OSX_CROSS_PATH}"
RUN git clone https://github.com/tpoechtrager/osxcross.git . \
 && git checkout -q "${OSX_CROSS_COMMIT}" \
 && rm -rf ./.git
COPY --from=osx-sdk "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ARG OSX_VERSION_MIN
RUN UNATTENDED=yes OSX_VERSION_MIN=${OSX_VERSION_MIN} OCDEBUG=1 ./build.sh
RUN rm -rf "${OSX_CROSS_PATH}/tarballs/*"

# Adding libtool to osxcross
FROM base AS libtool
ARG LIBTOOL_VERSION
ARG OSX_CODENAME
ARG OSX_SDK
RUN mkdir -p "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/"
RUN curl -fsSL "https://homebrew.bintray.com/bottles/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz" \
	| gzip -dc | tar xf - \
		-C "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/" \
		--strip-components=2 \
		"libtool/${LIBTOOL_VERSION}/include/" \
		"libtool/${LIBTOOL_VERSION}/lib/"

# Making the final image with goreleaser and osxcross
FROM osx-cross-base AS final
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y -q --no-install-recommends \
    libltdl-dev \
    gcc-multilib \
    g++-multilib \
    gcc-mingw-w64 \
    g++-mingw-w64 \
    parallel \
 && curl -sfL https://install.goreleaser.com/github.com/goreleaser/goreleaser.sh | sh -s -- -b /usr/local/bin \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=osx-cross "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
COPY --from=libtool   "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ENV PATH=${OSX_CROSS_PATH}/target/bin:$PATH

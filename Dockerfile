# Golang docker image options
ARG GO_IMAGE=buster
ARG GO_VERSION=1.19.0

# Libtool arguments
ARG LIBTOOL_VERSION=2.4.6_3
ARG LIBTOOL_SUM=9e4b12c13734a5f1b72dfd48aa71faa8fd81bbf2d16af90d1922556206caecc3

# Packages repository as dependencies to build
ARG REPO_URL=https://github.com/vxcontrol/vxbuild-cross/releases/download/v0.0.0

# Mac OS SDK used to osxcross
ARG OSX_SDK=MacOSX10.15.sdk
ARG OSX_SDK_SUM=d97054a0aaf60cb8e9224ec524315904f0309fbbbac763eb7736bdfbdad6efc8

# osxcross arguments
ARG OSX_VERSION_MIN=10.12
ARG OSX_CODENAME=catalina
ARG OSX_CROSS_COMMIT=bee9df60f169abdbe88d8529dbcc1ec57acf656d
ARG OSX_CROSS_REQUIREMENTS="libssl-dev libxml2-dev zlib1g-dev"

# Preparing base part of target image
FROM golang:${GO_VERSION}-${GO_IMAGE} AS base
ARG APT_MIRROR
RUN sed -ri "s/(httpredir|deb).debian.org/${APT_MIRROR:-deb.debian.org}/g" /etc/apt/sources.list \
 && sed -ri "s/(security).debian.org/${APT_MIRROR:-security.debian.org}/g" /etc/apt/sources.list
ENV OSX_CROSS_PATH=/osxcross

# Pulling and checking SDK tarball
FROM base AS osx-sdk
ARG OSX_SDK
ARG OSX_SDK_SUM
ARG REPO_URL
ADD ${REPO_URL}/${OSX_SDK}.tar.xz "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"
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
ARG LIBTOOL_SUM
ARG OSX_CODENAME
ARG OSX_SDK
ARG REPO_URL
ADD ${REPO_URL}/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz "${OSX_CROSS_PATH}/tarballs/libtool-${LIBTOOL_VERSION}.tar.gz"
RUN echo "${LIBTOOL_SUM}" "${OSX_CROSS_PATH}/tarballs/libtool-${LIBTOOL_VERSION}.tar.gz" | sha256sum -c -
RUN mkdir -p "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/"
RUN gzip -dc "${OSX_CROSS_PATH}/tarballs/libtool-${LIBTOOL_VERSION}.tar.gz" | tar xf - \
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
    jq \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=osx-cross "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
COPY --from=libtool   "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ENV PATH=${OSX_CROSS_PATH}/target/bin:$PATH

# vxbuild-cross
Cross compile build system to assemble VXMonitor project.

[This repo](https://github.com/vxcontrol/vxbuild-cross) contains a Dockerfile for building an image which is used to cross compile golang. It includes the MinGW compiler for windows, and an OSX SDK via [osxcross](https://github.com/tpoechtrager/osxcross).

These images are available from https://hub.docker.com/r/vxcontrol/vxbuild-cross and is used to build.

**Important**: these images was builded with OSX SDK 10.15 to make it with 10.10 or 10.11 SDKs, please, use custom builds from Building part of Readme.

## Fork
This project based on original repository by [docker/golang-cross](https://github.com/docker/golang-cross).

## Default arguments
```Dockerfile
# Golang docker image options
ARG GO_IMAGE=buster
ARG GO_VERSION=1.17.0

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
```

## Building

### The simple way
```bash
docker build -t local/vxbuild-cross:latest .
```

### Build with state cleanup
```bash
docker build --no-cache -t local/vxbuild-cross:latest .
```

### Use arguments to choose golang version
```bash
docker build \
 --build-arg GO_IMAGE="stretch" \
 --build-arg GO_VERSION="1.17.0" \
 -t local/vxbuild-cross:1.17.0-stretch .
```

### Use arguments to choose MacOS SDK 10.10
```bash
docker build \
 --build-arg LIBTOOL_VERSION="2.4.6_1" \
 --build-arg LIBTOOL_SUM="0eb206c0f51e8ce2e3e9340b5ce3c8ecef961ae6696f676073327a7ac04e5c0b" \
 --build-arg OSX_CODENAME="yosemite" \
 --build-arg OSX_CROSS_COMMIT="ee54d9fd43b45947ee74c99282b360cd27a8f1cb" \
 --build-arg OSX_CROSS_REQUIREMENTS="" \
 --build-arg OSX_VERSION_MIN="10.10" \
 --build-arg OSX_SDK="MacOSX10.10.sdk" \
 --build-arg OSX_SDK_SUM="631b4144c6bf75bf7a4d480d685a9b5bda10ee8d03dbf0db829391e2ef858789" \
 -t local/vxbuild-cross:10.10-sdk .
```

### Use arguments to choose MacOS SDK 10.11
```bash
docker build \
 --build-arg LIBTOOL_VERSION="2.4.6_1" \
 --build-arg LIBTOOL_SUM="b7651d0a082e2f103f03ca3a5ed831e2ff5655ccc1044ac0452e4d1825475a35" \
 --build-arg OSX_CODENAME="el_capitan" \
 --build-arg OSX_CROSS_COMMIT="ee54d9fd43b45947ee74c99282b360cd27a8f1cb" \
 --build-arg OSX_CROSS_REQUIREMENTS="" \
 --build-arg OSX_VERSION_MIN="10.11" \
 --build-arg OSX_SDK="MacOSX10.11.sdk" \
 --build-arg OSX_SDK_SUM="98cdd56e0f6c1f9e1af25e11dd93d2e7d306a4aa50430a2bc6bc083ac67efbb8" \
 -t local/vxbuild-cross:10.10-sdk .
```

### Use arguments to choose MacOS SDK 10.15 (by default)
```bash
docker build \
 --build-arg LIBTOOL_VERSION="2.4.6_3" \
 --build-arg LIBTOOL_SUM="9e4b12c13734a5f1b72dfd48aa71faa8fd81bbf2d16af90d1922556206caecc3" \
 --build-arg OSX_CODENAME="catalina" \
 --build-arg OSX_CROSS_COMMIT="bee9df60f169abdbe88d8529dbcc1ec57acf656d" \
 --build-arg OSX_CROSS_REQUIREMENTS="libssl-dev libxml2-dev zlib1g-dev" \
 --build-arg OSX_VERSION_MIN="10.12" \
 --build-arg OSX_SDK="MacOSX10.15.sdk" \
 --build-arg OSX_SDK_SUM="d97054a0aaf60cb8e9224ec524315904f0309fbbbac763eb7736bdfbdad6efc8" \
 -t local/vxbuild-cross:10.15-sdk .
```

## Using

### Check golang version

* `docker run --rm vxcontrol/vxbuild-cross go version`

### Simple attach to container

* `docker run --rm -it vxcontrol/vxbuild-cross /bin/bash`
* `docker run --rm -v /host/gopath:/go -it vxcontrol/vxbuild-cross /bin/bash`

### Cross compile simple Go project (docker container inside)

* `GOOS=linux GOARCH=amd64 go build`
* `GOOS=linux GOARCH=386 go build`
* `GOOS=darwin GOARCH=amd64 go build`
* `GOOS=darwin GOARCH=386 go build`
* `GOOS=windows GOARCH=amd64 go build`
* `GOOS=windows GOARCH=386 go build`

### Cross compile Go project with cgo (docker container inside)

* `GOOS=linux GOARCH=amd64 CC=gcc CXX=g++ CGO_ENABLED=1 go build`
* `GOOS=linux GOARCH=386 CC=gcc CXX=g++ CGO_ENABLED=1 go build`
* `GOOS=darwin GOARCH=amd64 CC=o64-clang CXX=o64-clang++ CGO_ENABLED=1 go build`
* `GOOS=darwin GOARCH=386 CC=o32-clang CXXo32-clang++ CGO_ENABLED=1 go build`
* `GOOS=windows GOARCH=amd64 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ CGO_ENABLED=1 go build`
* `GOOS=windows GOARCH=386 CC=i686-w64-mingw32-gcc CXX=i686-w64-mingw32-g++ CGO_ENABLED=1 go build`

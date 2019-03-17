FROM ubuntu:18.04

WORKDIR /mnt

ENV MINGW=/mingw

ARG PKG_CONFIG_VERSION=0.29.2
ARG CMAKE_VERSION=3.14.0
ARG BINUTILS_VERSION=2.32
ARG MINGW_VERSION=6.0.0
ARG GCC_VERSION=8.3.0
ARG NASM_VERSION=2.14.02
ARG NVCC_VERSION=10.1.105

SHELL [ "/bin/bash", "-c" ]

RUN set -ex \
    \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --no-install-recommends -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        ca-certificates \
        gcc-8 \
        g++-8 \
        zlib1g-dev \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
        libisl-dev \
        libgmp10 \
        libmpfr6 \
        libmpc3 \
        libisl19 \
        xz-utils \
        python \
        python-lxml \
        python-mako \
        ninja-build \
        meson \
        gnupg \
        bzip2 \
        patch \
        gperf \
        bison \
        file \
        flex \
        make \
        yasm \
        wget \
        zip \
    \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
    \
    && wget -q https://pkg-config.freedesktop.org/releases/pkg-config-${PKG_CONFIG_VERSION}.tar.gz -O - | tar -xz \
    && wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz -O - | tar -xz \
    && wget -q https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz -O - | tar -xJ \
    && wget -q https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v${MINGW_VERSION}.tar.bz2 -O - | tar -xj \
    && wget -q https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz -O - | tar -xJ \
    && wget -q https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.xz -O - | tar -xJ \
    \
    && mkdir -p ${MINGW}/include ${MINGW}/lib/pkgconfig \
    && chmod 0777 -R /mnt ${MINGW} \
    \
    && cd pkg-config-${PKG_CONFIG_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --with-pc-path=${MINGW}/lib/pkgconfig \
        --with-internal-glib \
        --disable-shared \
        --disable-nls \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd cmake-${CMAKE_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --parallel=`nproc` \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd binutils-${BINUTILS_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --target=x86_64-w64-mingw32 \
        --disable-shared \
        --enable-static \
        --disable-lto \
        --disable-plugins \
        --disable-multilib \
        --disable-nls \
        --disable-werror \
        --with-system-zlib \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && mkdir mingw-w64 \
    && cd mingw-w64 \
    && ../mingw-w64-v${MINGW_VERSION}/mingw-w64-headers/configure \
        --prefix=/usr/local/x86_64-w64-mingw32 \
        --host=x86_64-w64-mingw32 \
        --enable-sdk=all \
        --enable-secure-api \
    && make install \
    && cd .. \
    \
    && mkdir gcc \
    && cd gcc \
    && ../gcc-${GCC_VERSION}/configure \
        --prefix=/usr/local \
        --target=x86_64-w64-mingw32 \
        --enable-languages=c,c++ \
        --disable-shared \
        --enable-static \
        --enable-threads=posix \
        --with-system-zlib \
        --enable-libgomp \
        --enable-libatomic \
        --enable-graphite \
        --disable-libstdcxx-pch \
        --disable-libstdcxx-debug \
        --disable-multilib \
        --disable-lto \
        --disable-nls \
        --disable-werror \
    && make -j`nproc` all-gcc \
    && make install-gcc \
    && cd .. \
    \
    && cd mingw-w64 \
    && ../mingw-w64-v${MINGW_VERSION}/mingw-w64-crt/configure \
        --prefix=/usr/local/x86_64-w64-mingw32 \
        --host=x86_64-w64-mingw32 \
        --enable-wildcard \
        --disable-lib32 \
        --enable-lib64 \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd mingw-w64 \
    && ../mingw-w64-v${MINGW_VERSION}/mingw-w64-libraries/winpthreads/configure \
        --prefix=/usr/local/x86_64-w64-mingw32 \
        --host=x86_64-w64-mingw32 \
        --enable-static \
        --disable-shared \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd gcc \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd nasm-${NASM_VERSION} \
    && ./configure --prefix=/usr/local \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && rm -r pkg-config-${PKG_CONFIG_VERSION} \
    && rm -r cmake-${CMAKE_VERSION} \
    && rm -r binutils-${BINUTILS_VERSION} \
    && rm -r mingw-w64 mingw-w64-v${MINGW_VERSION} \
    && rm -r gcc gcc-${GCC_VERSION} \
    && rm -r nasm-${NASM_VERSION} \
    \
    && apt-get remove --purge -y file gcc-8 g++-8 zlib1g-dev libgmp-dev libmpfr-dev libmpc-dev libisl-dev python-lxml python-mako \
    \
    && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub \
    && wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_${NVCC_VERSION}-1_amd64.deb \
    && dpkg -i cuda-repo-ubuntu*_amd64.deb \
    && rm cuda-repo-ubuntu*_amd64.deb \
    && apt-get update \
    \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        automake \
        gettext \
        libtool \
        gcc-7 \
        g++-7 \
        cuda-nvcc-${NVCC_VERSION:0:2}-${NVCC_VERSION:3:1} \
    \
    && ln -s /usr/local/cuda-${NVCC_VERSION:0:2}.${NVCC_VERSION:3:1} /usr/local/cuda \
    && ln -s /usr/bin/gcc-7 /usr/local/cuda/bin/gcc \
    && ln -s /usr/bin/g++-7 /usr/local/cuda/bin/g++ \
    \
    && apt-get remove --purge -y gnupg \
    && apt-get autoremove --purge -y \
    && apt-get clean

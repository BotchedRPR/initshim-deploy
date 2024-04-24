#!/bin/sh
apk add meson gcc alpine-sdk cmake linux-headers git xz bash sudo cpio

rm -rfv libdrm-*
wget https://dri.freedesktop.org/libdrm/libdrm-2.4.120.tar.xz
tar -xf libdrm-2.4.120.tar.xz
cd libdrm-2.4.120/
mkdir build
cd    build
meson setup --prefix=/libdrm-2.4.120/build/out --buildtype release -Dvalgrind=disabled -Ddefault_library=static ..
ninja
ninja install

# build initshim here

set -e
cd /
rm -rfv initshim
mkdir initshim
cd initshim
git clone https://github.com/SebaUbuntu/AIK-Linux-mirror
cd AIK-Linux-mirror
mv /in.img in.img
./unpackimg.sh in.img
./repackimg.sh

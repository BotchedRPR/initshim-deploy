#!/bin/sh
apk add meson gcc alpine-sdk cmake linux-headers git xz bash sudo cpio libdrm-dev

# Static LibDRM
rm -rfv libdrm-*
wget https://dri.freedesktop.org/libdrm/libdrm-2.4.120.tar.xz
tar -xf libdrm-2.4.120.tar.xz
cd libdrm-2.4.120/
mkdir build
cd    build
meson setup --buildtype release -Dvalgrind=disabled -Ddefault_library=static ..
ninja
ninja install

# Initshim
cd /
rm -rfv build
mkdir build
cd build
if [ $# -eq 0 ]
then 
    git clone --depth 1 https://github.com/BotchedRPR/initshim
fi
if [ ! -z "$1" ]
then
    git clone --depth 1 --branch $1 https://github.com/BotchedRPR/initshim
fi
cd initshim
cmake .
C_INCLUDE_PATH="/usr/local/include/libdrm" make

# Injecting
set -e
cd /
rm -rfv initshim
mkdir initshim
cd initshim
git clone https://github.com/SebaUbuntu/AIK-Linux-mirror
cd AIK-Linux-mirror
mv /in.img in.img
./unpackimg.sh in.img
cp ramdisk/system/bin/init ramdisk/system/bin/init.rec
cp /build/initshim/initshim ramdisk/system/bin/init
chmod +x ramdisk/system/bin/init
./repackimg.sh

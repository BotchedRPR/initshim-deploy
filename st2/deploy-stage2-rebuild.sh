#!/bin/sh
# Initshim
cd /build/initshim
cmake .
C_INCLUDE_PATH="/usr/local/include/libdrm" make
set -e
cd /
cd initshim
cd AIK-Linux-mirror
./unpackimg.sh in.img
cp ramdisk/system/bin/init ramdisk/system/bin/init.rec
cp /build/initshim/initshim ramdisk/system/bin/init
chmod +x ramdisk/system/bin/init
./repackimg.sh
exit 3

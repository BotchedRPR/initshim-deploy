#!/bin/sh


# 0. Check arguments
if [  -z "$1" ] 
then
    echo "deploy.sh - inject initshim to a recovery image"
    printf "\nUsage: deploy.sh [recovery image file]\n\n"
    echo "Should be self explanatory, right?"
    echo "TODO: Add a tag parameter, make it work on local repos, etc"
    exit 2
fi
if ! test -f $1; then
    echo "The input file must be a valid Android recovery image."
    exit 1
fi

# 0.5. Clean up.
sudo umount -l st2/rootfs/proc
sudo umount -R -l st2/rootfs/sys
sudo umount -R -l st2/rootfs/dev


# 1. Prepare chroot rootfs
echo "Preparing Alpine chroot"
FILE=`wget -qO- "http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/latest-releases.yaml" | grep -o -m 1 'alpine-minirootfs-.*.tar.gz'`
wget "http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/$FILE" -O rootfs.tar.gz
tar -xf rootfs.tar.gz -C st2/rootfs/
cp $1 st2/rootfs/in.img
rm rootfs.tar.gz
cp st2/deploy-stage2.sh st2/rootfs/run.sh
cp /etc/resolv.conf st2/rootfs/etc/resolv.conf
chmod +x st2/rootfs/run.sh
set -e

# 2. Preparing bind mounts
sudo mount -t proc none st2/rootfs/proc
sudo mount --rbind /dev st2/rootfs/sys
sudo mount --make-rslave st2/rootfs/sys
sudo mount --rbind /dev st2/rootfs/dev
sudo mount --make-rslave st2/rootfs/dev

# 3. Let's go!
echo "Working in alpine chroot..."
echo "If you do not get an output file please look at log.txt. Thanks bye"
sudo chroot st2/rootfs /run.sh

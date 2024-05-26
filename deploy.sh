#!/bin/sh


# 0. Check arguments
if [  -z "$1" ] 
then
    echo "deploy.sh - inject initshim to a recovery image"
    printf "\nUsage: deploy.sh [recovery image file] <local initshim repo dir> \n\n"
    echo "Should be self explanatory, right?"
    echo "TODO: Add a tag parameter, make it work on local repos, etc"
    exit 2
fi

if [ "$3" = "rebuild_only_is" ]; then
	cp st2/deploy-stage2-rebuild.sh st2/rootfs/run.sh
	sudo mount -t proc none st2/rootfs/proc
	sudo mount --rbind /dev st2/rootfs/sys
	sudo mount --make-rslave st2/rootfs/sys
	sudo mount --rbind /dev st2/rootfs/dev
	sudo mount --make-rslave st2/rootfs/dev
	sudo rm -rfv st2/rootfs/build/initshim
	sudo cp -rv $2 st2/rootfs/build/initshim	
	sudo chroot st2/rootfs /run.sh rebuild > log.txt
	exit 1
fi

if ! test -f $1; then
    echo "The input file must be a valid Android recovery image."
    exit 1
fi

# 0.5. Clean up. Just in case. We really don't want to have multiple layers mounted
sudo umount -R -l st2/rootfs/proc
sudo umount -R -l st2/rootfs/sys
sudo umount -R -l st2/rootfs/dev

# 1. Prepare chroot rootfs
echo "Preparing Alpine chroot"
FILE=`wget -qO- "http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/latest-releases.yaml" | grep -o -m 1 'alpine-minirootfs-.*.tar.gz'`
wget "http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/$FILE" -O rootfs.tar.gz
tar -xf rootfs.tar.gz -C st2/rootfs/
cp $1 st2/rootfs/in.img
rm rootfs.tar.gz
rm st2/rootfs/run.sh
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
sudo rm -rfv st2/rootfs/build/initshim
if [ -z "$2" ]
then
    sudo git clone --depth 1 https://github.com/BotchedRPR/initshim st2/rootfs/build/initshim
else

    sudo cp -rv $2 st2/rootfs/build/initshim
fi

echo "Working in alpine chroot..."
echo "If you do not get an output file please look at log.txt. Thanks bye"
sudo chroot st2/rootfs /run.sh > log.txt

if sudo cp st2/rootfs/initshim/AIK-Linux-mirror/unsigned-new.img injected-recovery.img; then
    echo "Injecting done! Have fun!"
else
    echo "FAIL, Look at log.txt"
fi

# 4. Clean up - DO THIS LATER
#sudo umount -R -l st2/rootfs/proc
#sudo umount -R -l st2/rootfs/sys
#sudo umount -R -l st2/rootfs/dev

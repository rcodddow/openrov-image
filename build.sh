#!/bin/sh

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root or with sudo" 1>&2
   exit 1
fi

if [ "$1" = "" ]; then
	echo "Please pass the name of the elinux ubuntu image (from http://elinux.org/BeagleBoardUbuntu) as the first argument."
	exit 1
fi

export IMAGE=$1
export NODEGIT=https://github.com/joyent/node.git
export NODEVERSION=v0.10.15
export MJPG_STREAMERGIT=https://github.com/codewithpassion/mjpg-streamer.git
export INOGIT=https://github.com/amperka/ino.git

export DIR=${PWD#}

IMAGE_FULLNAME=$(basename "$IMAGE")
IMAGE_NAME="${IMAGE_FULLNAME%%.*}"

# extract the image
tar xf $IMAGE
cd $IMAGE_NAME

# extract the root fs
mkdir root
cd root
export ROOT=${PWD#}

echo Extracting rootfs
tar xf ../armhf-rootfs-*.tar

echo Mounting system directories
mount --bind /dev/ dev/
mount --bind /proc/ proc/
mount --bind /sys/ sys/
mount --bind /run/ run/
mount --bind /etc/resolv.conf etc/resolv.conf

# copy qemu for chrooting
cp /usr/bin/qemu-arm-static usr/bin/

# build node
sh $DIR/lib/nodejs.sh $DIR/work $NODEGIT $NODEVERSION $ROOT/tmp/work/node/

# get mjpeg-streamer
cd $ROOT/tmp/work
git clone $MJPG_STREAMERGIT mjpg-streamer

# get ino
cd $ROOT/tmp/work
git clone https://github.com/amperka/ino.git ino
cd ino
wget http://peak.telecommunity.com/dist/ez_setup.py


cd $ROOT/opt
git clone https://github.com/OpenROV/openrov-software.git openrov
cd openrov
npm install --arch=arm
cd $ROOT


cp $DIR/lib/customizeroot.sh ./tmp/
chroot . /tmp/customizeroot.sh

echo Unmounting system directories
umount etc/resolv.conf
umount run
umount sys
umount proc
umount dev

cd $ROOT
tar cf ../armhf-rootfs-ubuntu-saucy.tar .

cd $IMAGE_NAME
sed -i 's/\[1024\*800\]/\[1024*1200]/' setup_sdcard.sh

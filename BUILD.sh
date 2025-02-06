#!/bin/bash

REPLACEMENT_MIRROR="deb.debian.org"

# Initial setup and required packages

export DEBIAN_FRONTEND="noninteractive"
apt update
apt install -y git ssh make gcc libssl-dev liblz4-tool expect expect-dev g++ patchelf chrpath gawk texinfo \
    diffstat binfmt-support qemu-user-static bison flex fakeroot cmake gcc-multilib g++-multilib \
    unzip device-tree-compiler ncurses-dev libgucharmap-2-90-dev bzip2 expat gpgv2 cpp-aarch64-linux-gnu \
    libgmp-dev libmpc-dev bc python-is-python3 python2 rsync sudo vim curl iputils-ping

# Python2 symlink
sudo ln -sf /usr/bin/python2 /usr/bin/python

# Setup live-build from source to avoid issues with the version in the repos
sudo apt-get remove live-build -y
git clone https://salsa.debian.org/live-team/live-build.git --depth 1 -b debian/1%20230131
cd live-build
rm -rf manpages/po/
# use jproc  instead of -j16
sudo make install -j$(nproc)
cd ..

# Setup build environment
export RK_ROOTFS_SYSTEM=debian
git config --global --add safe.directory /Omni3576-sdk/.repo/manifests

# Extract source and build
tar -xzvf luckfox-omni3576-*.tar.gz
.repo/repo/repo sync -l
git config --global --add safe.directory /luckfox/.repo/manifests
.repo/repo/repo sync -l

# Replace mirror mirrors.ustc.edu.cn with $REPLACEMENT_MIRROR
sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/ubuntu-build-service/bookworm-base-arm64/configure
export RK_DEBIAN_MIRROR=$REPLACEMENT_MIRROR

./build.sh lunch

# remove the sudo -u part of export KMAKE="sudo -u $RK_OWNER_UID $KMAKE" part so the command becomes      export KMAKE="$KMAKE" in the device/rockchip/common/scripts/kernel-helper
sed -i 's/sudo -u $RK_OWNER_UID //g' device/rockchip/common/scripts/kernel-helper

./build.sh

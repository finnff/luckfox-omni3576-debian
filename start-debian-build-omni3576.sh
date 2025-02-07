#!/bin/bash

# Create Dockerfile for the build environment
cat >Dockerfile <<'EOF'
FROM ubuntu:22.04

# Create non-root user
RUN useradd -m -u 1000 builder && \
    apt-get update && \
    apt-get install -y sudo && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder

# Set working directory
WORKDIR /luckfox

# Copy the build script
COPY BUILD.sh /BUILD.sh
RUN chmod +x /BUILD.sh && \
    chown builder:builder /BUILD.sh

# Switch to non-root user
USER builder

EOF

# Create the build script that will run inside the container
cat >BUILD.sh <<'EOF'
#!/bin/bash
REPLACEMENT_MIRROR="deb.debian.org"
# Initial setup and required packages
export DEBIAN_FRONTEND="noninteractive"

if [ ! -f "debian/ubuntu-build-service/bookworm-base-arm64/configure" ]; then
    sudo apt-get update
    sudo apt-get install -y git ssh make gcc libssl-dev liblz4-tool expect expect-dev g++ patchelf chrpath gawk texinfo \
        diffstat binfmt-support qemu-user-static bison flex fakeroot cmake gcc-multilib g++-multilib \
        unzip device-tree-compiler ncurses-dev libgucharmap-2-90-dev bzip2 expat gpgv2 cpp-aarch64-linux-gnu \
        libgmp-dev libmpc-dev bc python-is-python3 python2 rsync sudo vim curl iputils-ping debootstrap file cpio \
        bsdmainutils

    # Python2 symlink
    sudo ln -sf /usr/bin/python2 /usr/bin/python

    # Setup live-build from source
    sudo apt-get remove live-build -y
    git clone https://salsa.debian.org/live-team/live-build.git --depth 1 -b debian/1%20230131
    cd live-build
    rm -rf manpages/po/
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
fi

# Replace mirror
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/ubuntu-build-service/bookworm-base-arm64/configure
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/ubuntu-build-service/bookworm-xfce-arm64/configure
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/ubuntu-build-service/bookworm-lxde-arm64/configure
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/ubuntu-build-service/bookworm-gnome-arm64/configure
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/scripts/rockbian.sh
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/mk-rootfs-bookworm.sh
export RK_DEBIAN_MIRROR=$REPLACEMENT_MIRROR

# Update symlink
sudo rm -f debian/ubuntu-build-service/bookworm-desktop-arm64
sudo ln -s bookworm-base-arm64 debian/ubuntu-build-service/bookworm-desktop-arm64

./build.sh lunch


# Configure and build kernel
cd kernel-6.1 || exit
cp DOCKERKERNEL .config
make ARCH=arm64 olddefconfig
cd ..

./build.sh kernel
./build.sh
EOF

# Build the Docker image
docker build -t luckfox-builder .

# Run the container with the non-root user
docker run -it \
    -v $PWD:/luckfox \
    -v /dev:/dev \
    --privileged \
    luckfox-builder \
    /BUILD.sh

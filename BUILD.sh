#!/bin/bash

# This can be set to "base", "xfce", "lxde", "gnome"
REPLACEMENT_DESKTOP_ENVIORMENT="base"
# Replace with mirror from https://www.debian.org/mirror/list (optional)
#REPLACEMENT_MIRROR="deb.debian.org"

REPLACEMENT_MIRROR="ftp.nl.debian.org"

if [ ! -f "debian/ubuntu-build-service/bookworm-base-arm64/configure" ]; then
    # Setup live-build from source
    sudo apt-get update
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

# Replace mirror mirrors.ustc.edu.cn with $REPLACEMENT_MIRROR
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/ubuntu-build-service/bookworm-base-arm64/configure
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/ubuntu-build-service/bookworm-xfce-arm64/configure
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/ubuntu-build-service/bookworm-lxde-arm64/configure
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/ubuntu-build-service/bookworm-gnome-arm64/configure
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/scripts/rockbian.sh
sudo sed -i "s/mirrors.ustc.edu.cn/$REPLACEMENT_MIRROR/g" debian/mk-rootfs-bookworm.sh
export RK_DEBIAN_MIRROR=$REPLACEMENT_MIRROR

# remove existing simlink for debian/ubuntu-build-service/bookworm-desktop-arm64 and then simlink it to bookworm-base-arm64
sudo rm -f debian/ubuntu-build-service/bookworm-desktop-arm64
sudo ln -s bookworm-$REPLACEMENT_DESKTOP_ENVIORMENT-arm64 debian/ubuntu-build-service/bookworm-desktop-arm64

# Create expect script for handling all build.sh prompts
cat >build_commands.exp <<'EXPECT_EOF'
#!/usr/bin/expect -f
set timeout -1

# Handle build.sh lunch
spawn ./build.sh lunch
expect {
    "Which would you like? \\\[1\\\]:" {
        send "2\r"
        exp_continue
    }
    "Press enter to continue." {
        send "\r"
        exp_continue
    }
    eof
}


# Load the ./DOCKERKERNEL file as kernel config to ensure we have the modules running docker
exec cp DOCKERKERNEL kernel-6.1/.config
cd kernel-6.1
exec make ARCH=arm64 olddefconfig
cd ..

# Handle build.sh kernel
spawn ./build.sh kernel
expect {
    "Press enter to continue." {
        send "\r"
        exp_continue
    }
    eof
}

# Handle final build.sh
spawn ./build.sh
expect {
    "Press enter to continue." {
        send "\r"
        exp_continue
    }
    eof
}
EXPECT_EOF

chmod +x build_commands.exp
./build_commands.exp

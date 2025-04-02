# Debian-Base Dockerized Build for Luckfox Omni-3576  

This project provides a containerized way of building Debian-based images for the [Luckfox Omni-3576](https://www.luckfox.com/EN-Luckfox-Omni3576). I faced significant difficulties even extracting the SDK on a non-Ubuntu 22.04 system, so this setup ensures a one-click script to consistently produce Debian images that include the necessary kernel modules for running Docker out of the box—without rewriting large parts of the existing [Luckfox SDK build scripts](https://wiki.luckfox.com/luckfox-Omni3576/Luckfox-Omni3576-SDK/#2-compiling-images-in-ubuntu-2204-environment).


## Prerequisites 
* Linux host with docker installed
* Downloaded SDK from [wiki.luckfox.com](https://wiki.luckfox.com/Luckfox-Omni3576/Download/)
* At least 60GB of free disk space

## Overview  
- A **Dockerfile** sets up an Ubuntu 22.04 build environment with all necessary dependencies.  
- **start-debian-build-omni3576.sh** extracts the Luckfox SDK tarball, enables the required kernel options as specified in **DOCKERKERNEL**, replaces the default Chinese Debian mirror, and automates interactions with the Luckfox SDK build process to make it fully unattended.  
- The script does not modify the SDK itself, except for enabling certain kernel options and replacing download mirrors.  


## Usage

1. Clone this repo:  
   ```bash
   git clone https://github.com/finnff/luckfox-omni3576-debian.git && cd luckfox-omni3576-debian
   ```

2. Download the SDK from [wiki.luckfox.com](https://wiki.luckfox.com/Luckfox-Omni3576/Download/) and move it to this directory:  
   ```bash
   mv ~/Downloads/luckfox-omni3576-*.tar.gz .
   ```

. (Optional) Modify the `BUILD.sh` script:  
   - Change the mirror: `REPLACEMENT_MIRROR="deb.debian.org"` (see [Debian mirrors](https://www.debian.org/mirror/list))  
   - Select a desktop environment by changing `REPLACEMENT_DESKTOP_ENVIORMENT="base"` to `"xfce"`, `"lxde"`, or `"gnome"`.  

4. Start the build process:  
   ```bash
   ./start-debian-build-omni3576.sh
   ```

The process will take time (about 45mins on a 8 core ryzen), preparing the ubuntu build environment, compiling the kernel and generating the Debian image. A successful build will conclude with:  

```
Description: Kbuild and headers for Rockchip Linux 6.1 arm64 configuration
Packing linux-headers-6.1-arm64_aarch64.deb...
Running mk-kernel.sh - linux-headers-aarch64 succeeded.
Running mk-kernel.sh - linux-headers succeeded.
Running 99-all.sh - build_all succeeded.
```

You will find the final image at:  
```
$ ls -lh output/update/Image/update.img   
-rw-r--r-- 1 user user 3.5G Feb  7 06:30 output/update/Image/update.img
```


## Flashing to eMMC  

Refer to the instructions on how to enter **Loader Mode** or **MaskROM Mode**:  
[Luckfox Wiki - Enter Upgrade Mode](https://wiki.luckfox.com/luckfox-Omni3576/Burn-image#31-enter-upgrade-mode)

You can use this command to monitor the mode:  
```bash
watch -n 1 lsusb
```  
Once in the correct mode, flash the built image by running the following on your **host system** (not inside the container):  
```bash
./rkflash.sh update
```


## First Boot  

Once flashed, you can SSH into the device using:  
```bash
ssh luckfox@<device-ip>  # Default password: luckfox
```

For Docker compatibility, you may need to update iptables settings before you can start the docker socket:  
```bash
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo systemctl restart docker
```
You should now be able to install Docker and run containers on the device.  

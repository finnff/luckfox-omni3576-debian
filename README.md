
# Debian-Base Dockerized build for Luckfox Omni-3576  

Download the SDK from [wiki.luckfox.com](https://wiki.luckfox.com/Luckfox-Omni3576/Download/)  and move the luckfox-omni3576-*.tar.gz to this dir.

```
docker run -it -v .:/luckfox -v /dev:/dev --privileged  ubuntu:22.04  bash 
cd /luckfox
# replace REPLACEMENT_MIRROR in ./BUILD.sh with a different mirror if you dont want to use deb.debian.org
./BUILD.sh
```


# Flashing to eMMC

Flash on host system (ie not in docker container) with `./rkflash.sh update`

# SSH into the omni3576 with `luckfox:luckfox`

```
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```

You should now be able to install docker and run containers on the device.

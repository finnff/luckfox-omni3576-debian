FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam

# Install all required packages in the base image
RUN apt-get update && \
    apt-get install -y \
    git \
    ssh \
    make \
    gcc \
    libssl-dev \
    liblz4-tool \
    expect \
    expect-dev \
    g++ \
    patchelf \
    chrpath \
    gawk \
    texinfo \
    diffstat \
    binfmt-support \
    qemu-user-static \
    bison \
    flex \
    fakeroot \
    cmake \
    gcc-multilib \
    g++-multilib \
    unzip \
    device-tree-compiler \
    ncurses-dev \
    libgucharmap-2-90-dev \
    bzip2 \
    expat \
    gpgv2 \
    cpp-aarch64-linux-gnu \
    libgmp-dev \
    libmpc-dev \
    bc \
    python-is-python3 \
    python2 \
    rsync \
    sudo \
    vim \
    curl \
    iputils-ping \
    debootstrap \
    file \
    cpio \
    bsdmainutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Setup Python2 symlink in the base image
RUN ln -sf /usr/bin/python2 /usr/bin/python

# Create non-root user
RUN useradd -m -u 1000 builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder

# Set working directory
WORKDIR /luckfox

# Copy the build script
COPY BUILD.sh /BUILD.sh
RUN chmod +x /BUILD.sh && \
    chown builder:builder /BUILD.sh

# Switch to non-root user
USER builder


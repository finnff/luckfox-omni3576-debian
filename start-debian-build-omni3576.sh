#!/bin/bash

# Build the Docker image
docker build -t luckfox-builder .

# Run the container with the non-root user
docker run -it \
    -v $PWD:/luckfox \
    -v /dev:/dev \
    --privileged \
    luckfox-builder \
    /BUILD.sh

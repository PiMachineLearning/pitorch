#!/usr/bin/env bash

docker build -t pimachinelearning/pitorch-builder .
docker volume create ccache
echo "CCACHE_MOUNT=$(docker volume inspect ccache | jq '.[0]["Mountpoint"]')" >> $GITHUB_OUTPUT
docker run -e IGNORE_CORES=0 -e CCACHE_DIR=/ccache --mount source=ccache,target=/ccache pimachinelearning/pitorch-builder

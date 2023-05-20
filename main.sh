#!/usr/bin/env bash

docker build -t pimachinelearning/pitorch-builder .
docker volume create ccache
docker run -e IGNORE_CORES=0 -e CCACHE_DIR=/ccache --mount source=ccache,target=/ccache pimachinelearning/pitorch-builder

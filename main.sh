#!/usr/bin/env bash

docker build -t pimachinelearning/pitorch-builder .
docker volume create ccache
        # 5 hours 45 minutes, allow 15 minutes for the other the tasks
timeout 20700 docker run -e IGNORE_CORES=0 -e CCACHE_DIR=/ccache --mount source=ccache,target=/ccache pimachinelearning/pitorch-builder

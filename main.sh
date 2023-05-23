#!/usr/bin/env bash

docker build -t pimachinelearning/pitorch-builder .
docker volume create ccache
# kill -9 to make sure it's killed    5 hours, allow 1 hour for the other the tasks
timeout --signal=9 18000 docker run -e IGNORE_CORES=0 -e CCACHE_DIR=/ccache --mount source=ccache,target=/ccache pimachinelearning/pitorch-builder
sudo chmod -R 777 /var/lib/docker/volumes/ccache/_data

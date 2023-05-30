#!/usr/bin/env bash
docker pull pimachinelearning/pitorch-builder
if [ $? -eq 1 ]; then
  REBUILD=1
fi

git diff-tree --no-commit-id --name-only -r HEAD | grep -v .github | grep -v LICENSE | grep -v README.md | grep -v main.sh
if [ $? -eq 1 ]; then
  REBUILD=1
fi

if [ "$REBUILD" -eq 1 ]; then
  docker build -t pimachinelearning/pitorch-builder .
  docker tag pimachinelearning/pitorch-builder:latest pimachinelearning/pitorch-builder:latest
  docker push pimachinelearning/pitorch-builder:latest
fi
docker volume create ccache
# kill -9 to make sure it's killed    5 hours, allow 1 hour for the other the tasks
timeout --signal=9 18000 docker run -e IGNORE_CORES=0 -e CCACHE_DIR=/ccache --mount source=ccache,target=/ccache pimachinelearning/pitorch-builder
if [ $? -eq 0 ]; then
  DOCKER_ID=$(docker ps -aq -n 1)
  docker start $DOCKER_ID && docker exec $DOCKER_ID find -name *.whl
fi
  
sudo chmod -R 777 /var/lib/docker/

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
timeout --signal=9 18000 docker run -e IGNORE_CORES=0 -e CCACHE_DIR=/ccache -e PYTORCH_BUILD_VERSION=2.0.1 -e PYTORCH_BUILD_NUMBER=0 --mount source=ccache,target=/ccache pimachinelearning/pitorch-builder
if [ $? -eq 0 ]; then
  DOCKER_ID=$(docker ps -aq -n 1)
  docker start $DOCKER_ID
  WHEEL=$(docker exec $DOCKER_ID find -name *.whl)
  docker stop $DOCKER_ID --signal 9
fi
git clone https://__token__:$GITHUB_TOKEN@github.com/piMachineLearning/pimachinelearning.github.io/
cd pimachinelearning.github.io/ || exit 1
git config commit.gpgsign false
git config user.name 'Automated Committer'
git config user.email 'bot@malwarefight.wip.la'
cd wheels || exit 1
[[ -d torch ]] || mkdir torch
cd torch || exit 1
docker cp $(docker ps -aq -n 1):$WHEEL .
git add .
git commit -m "Automated commit: build torch"
git push -u origin main
sudo chmod -R 777 /var/lib/docker/

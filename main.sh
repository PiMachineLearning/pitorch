#!/usr/bin/env bash

docker pull pimachinelearning/pitorch-builder:"$1"
if [ $? -eq 1 ]; then
  REBUILD=1
fi

if git diff-tree --no-commit-id --name-only -r HEAD | grep -v .github | grep -v LICENSE | grep -v README.md | grep -v main.sh; then
  REBUILD=1
fi

if git log -1 --pretty=%B | grep '\[force build containers\]'; then
  REBUILD=1
fi

if [ "$REBUILD" -eq 1 ]; then
  docker build --build-arg PYTORCH_VER="$1" -t pimachinelearning/pitorch-builder:"$1" . || exit 1
  docker tag pimachinelearning/pitorch-builder:"$1" pimachinelearning/pitorch-builder:"$1"
  docker push pimachinelearning/pitorch-builder:"$1"
fi
docker volume create ccache
# kill -9 to make sure it's killed    5 hours, allow 1 hour for the other the tasks
timeout --signal=9 18000 docker run -e PYTORCH_VER=$1 -e IGNORE_CORES=0 -e CCACHE_DIR=/ccache --mount source=ccache,target=/ccache pimachinelearning/pitorch-builder
DOCKER_ID=$(docker ps -aq -n 1)
docker start "$DOCKER_ID"
WHEEL=$(docker exec "$DOCKER_ID" find -name '*torch*.whl')
echo "$WHEEL"
docker stop -t 0 "$DOCKER_ID" 
git clone https://__token__:"$GITHUB_TOKEN"@github.com/PiMachineLearning/staging/
cd staging/ || exit 1
git config commit.gpgsign false
git config user.name 'Automated Committer'
git config user.email 'bot@malwarefight.wip.la'
cd wheels || exit 1
[[ -d torch ]] || mkdir torch
cd torch || exit 1
docker cp "$(docker ps -aq -n 1)":"$WHEEL" .
git add .
git commit -m "Automated commit: build torch"
git push -u origin main
sudo chmod -R 777 /var/lib/docker/

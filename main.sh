#!/usr/bin/env bash

docker pull pimachinelearning/pitorch-builder:"$1"

REBUILD=0
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
  echo "Rebuilding..."
  docker build --build-arg PYTORCH_VER="$1" -t pimachinelearning/pitorch-builder:"$1" . || exit 1
  docker tag pimachinelearning/pitorch-builder:"$1" pimachinelearning/pitorch-builder:"$1"
  docker push pimachinelearning/pitorch-builder:"$1"
fi
docker volume create ccache
# kill -9 to make sure it's killed    5 hours, allow 1 hour for the other the tasks
timeout --signal=9 18000 docker run -e PYTORCH_BUILD_NUMBER=0 -e PYTORCH_BUILD_VERSION="$1" -e IGNORE_CORES=0 -e CCACHE_DIR=/ccache --mount source=ccache,target=/ccache pimachinelearning/pitorch-builder
DOCKER_ID=$(docker ps -aq -n 1)
docker start "$DOCKER_ID"
WHEEL=$(docker exec "$DOCKER_ID" find -name '*torch*.whl')
echo "$WHEEL"
docker stop -t 0 "$DOCKER_ID" 
docker cp "$(docker ps -aq -n 1)":"$WHEEL" .
LOCAL_FILE=$(ls | grep whl)
touch empty
while true
do
    # ensure that Sharin is not currently rebuilding the static repo
    echo -e "get uploader/Sharin/lock /dev/null" | sftp -b -  uploader@$VPS_HOST 
    if [ $? -ne 0 ]; then
        echo "safe to work" # not entirely due to data races, but risk is reduced
        break
    fi
    sleep 60
done
echo -e "put empty uploader/Sharin/lock" | sftp -b - uploader@$VPS_HOST 
echo -e "cd uploader/wheels/torch\nput $LOCAL_FILE" | sftp -b - uploader@$VPS_HOST
echo -e "rm uploader/Sharin/lock" | sftp uploader@$VPS_HOST

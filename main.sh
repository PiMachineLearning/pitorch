#!/usr/bin/env bash

docker build -t pimachinelearning/pitorch-builder .
docker run -e IGNORE_CORES=0 pimachinelearning/pitorch-builder
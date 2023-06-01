#!/usr/bin/env bash
for patch in $(ls *.patch)
do
  patch -p1 --batch < $patch
done

#!/bin/sh

docker run --volume="$PWD:/mnt/luarocks:Z" luarocks /mnt/luarocks/run-in-docker.sh

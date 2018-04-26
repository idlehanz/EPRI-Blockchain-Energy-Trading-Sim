#!/usr/bin/bash

# This script generates a node key for the bootnode.
IMAGE=${1:-'ethereum/client-go:alltools-stable'}

echo "Using image: $IMAGE"

OUT=$(docker run \
             --name bootnode-script \
             --entrypoint '' \
             $IMAGE sh -c \
             "bootnode --genkey /tmp/boot.key && cat /tmp/boot.key && echo '' && bootnode --nodekey /tmp/boot.key --writeaddress")

IFS=$'\n' read -rd '' -a LINES <<< "$OUT"
KEY=${LINES[0]}
URL=${LINES[1]}

# Save the things into Docker
echo $KEY | docker config create bootnode_key -
echo $URL | docker config create bootnode_url -

# Clean up
docker rm bootnode-script

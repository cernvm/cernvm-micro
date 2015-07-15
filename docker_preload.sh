#!/bin/sh

set -e

IMAGE=$1
DEST=$2

[ -z "$IMAGE" ] && exit 1
[ -z "$DEST" ] && exit 1

docker version || /sbin/service docker
IMG_ID=$(cat $IMAGE | docker import -)
docker run $IMG_ID /init /bin/true
CONT_ID=$(docker ps -a | grep $IMG_ID | awk '{print $1}')
TMP_DIR=$(mktemp -d)
mkdir "${TMP_DIR}/tmp"
docker cp $CONT_ID:/tmp/parrot.0 ${TMP_DIR}/tmp/
cd "$TMP_DIR" && tar -cvJf "$DEST" tmp
rm -rf "$TMP_DIR"
docker rm $CONT_ID
docker rmi $IMG_ID


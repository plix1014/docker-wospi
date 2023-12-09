#!/bin/bash


ENV=.env

if [ -f "$ENV" ]; then
    . $ENV
else
    . /opt/docker/wospi/$ENV
fi

if [ $# -ne 1 ]; then
    echo
    echo "usage: ${0##*/} <inc|full>"
    echo
    exit 1
fi

OPTS=

if [ "$1" = "full" ]; then
    OPTS="--no-cache"
fi

echo "docker build $OPTS --target $TARGET --build-arg="CONT_VER=$TAG" -t ${IMAGE_NAME}:$TAG"
time docker build $OPTS --target $TARGET --build-arg="CONT_VER=$TAG" -t ${IMAGE_NAME}:$TAG  .


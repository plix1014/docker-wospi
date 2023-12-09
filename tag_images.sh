#!/bin/bash


ENV=.env

if [ -f "$ENV" ]; then
    . $ENV
else
    . /opt/docker/wospi/$ENV
fi

echo
echo "tagging image"
echo "  docker image tag ${IMAGE_NAME}:${TAG} $REPO_USER_USER/${IMAGE_NAME}:${TAG}"
docker image tag ${IMAGE_NAME}:${TAG} $REPO_USER_USER/${IMAGE_NAME}:${TAG}

if ! [[ ${TAG} =~ image ]]; then
    echo "  docker image tag ${IMAGE_NAME}:${TAG} $REPO_USER_USER/${IMAGE_NAME}:latest"
    docker image tag ${IMAGE_NAME}:${TAG} $REPO_USER_USER/${IMAGE_NAME}:latest

    echo "  docker image tag ${IMAGE_NAME}:${TAG} $REPO_USER_USER/${IMAGE_NAME}:${WOSPI_VERSION}-RPi"
    docker image tag ${IMAGE_NAME}:${TAG} $REPO_USER_USER/${IMAGE_NAME}:${WOSPI_VERSION}-RPi
else
    echo "  for the dev TAG '${TAG}' we do not tag a 'latest'"
fi

echo
docker images | egrep "^REPOSITORY|${IMAGE_NAME}"


#!/bin/bash


ENV=.env

if [ -f "$ENV" ]; then
    . $ENV
else
    . /opt/docker/wospi/$ENV
fi

echo
echo "docker image push $REPO_USER_USER/${IMAGE_NAME}:${TAG}"
docker image push $REPO_USER_USER/${IMAGE_NAME}:${TAG}


if ! [[ ${TAG} =~ image ]]; then
    echo "docker image push $REPO_USER_USER/${IMAGE_NAME}:${WOSPI_VERSION}-RPi"
    docker image push $REPO_USER_USER/${IMAGE_NAME}:${WOSPI_VERSION}-RPi

    echo "docker image push $REPO_USER_USER/${IMAGE_NAME}:latest"
    docker image push $REPO_USER_USER/${IMAGE_NAME}:latest
else
    echo "  for the dev TAG '${TAG}' we do not push a 'latest'"
fi


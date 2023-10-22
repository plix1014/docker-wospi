#!/bin/bash

#TAG=${1:-0.7}
#

#HOMEDIR=/home/wospi


IMG_FUNC=${1:-app}

. .env

docker exec -ti ${IMAGE_NAME} bash


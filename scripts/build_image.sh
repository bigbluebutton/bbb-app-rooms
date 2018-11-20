#!/bin/bash

account="bigbluebutton"
if [[ -n "$1" ]]; then
    account=$1
    account=${account##*:}
    account=${account%%/*}
fi

tag="latest"
if [[ -n "$2" ]]; then
    tag=$2
fi

image="$account/bbb-lti-broker:$tag"

echo "Building $image ..."
docker build -t $image .

if [[ -v "${DOCKER_USER}" ]] && [[ -v "${DOCKER_PASS}" ]]; then
    echo "Publishing $image ..."
    docker login -u $DOCKER_USER -p $DOCKER_PASS
    docker push $image
    docker logout
fi

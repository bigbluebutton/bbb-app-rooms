#!/bin/bash

docker build -t bigbluebutton/lti_tool_provider:master .

docker login -u $DOCKER_USER -p $DOCKER_PASS
docker push bigbluebutton/lti_tool_provider:master

docker logout

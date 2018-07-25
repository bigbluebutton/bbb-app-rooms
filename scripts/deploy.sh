#!/usr/bin/env bash

## ACCESS_KEY and SECRET have to be set as environment variables either in the script or in the cron (or service)
# export AWS_ACCESS_KEY_ID=""
# export AWS_SECRET_ACCESS_KEY=""

if [ "$#" -ne 2 ]
then
  echo "Usage: castle-deploy.sh [local|aws] [latest|release-0.1 .. release-0.n]"
  exit 1
fi

## The docker-compose script used for each deployment is different [<production.yml>|aws-compose.yml]
case $1 in
  local)
  DOCKER_SCRIPT="production.yml"
  echo $DOCKER_SCRIPT
  ;;
  aws)
  DOCKER_SCRIPT="aws-compose.yml"
  echo $DOCKER_SCRIPT
  ;;
  *)
  echo "Usage: castle-deploy.sh [local|aws] [latest|release-0.1 .. release-0.n]"
  exit 1
  ;;
esac
echo "Processing $DOCKER_SCRIPT..."

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

STATUS="Status: Downloaded newer image for 486276134566.dkr.ecr.us-east-1.amazonaws.com/castle:$2"

authorization=$(aws ecr get-authorization-token --region us-east-1)
authorizationToken=$(echo $authorization | jq '.authorizationData[0].authorizationToken' | sed 's/\"//g' | base64 -d | cut -d: -f2)
proxyEndpoint=$(echo $authorization | jq '.authorizationData[0].proxyEndpoint' | sed 's/\"//g')
sudo docker login -u AWS -p $authorizationToken $proxyEndpoint

echo "Pull latest image..."
docker_pull=$(sudo docker pull 486276134566.dkr.ecr.us-east-1.amazonaws.com/castle:$2)
new_status=$(echo "$docker_pull" | grep Status:)
if [ "$STATUS" == "$new_status" ]; then
  echo "New image was found..."
  echo "...update BUILD_DIGEST..."
  image_digest=$(echo "$docker_pull" | grep Digest: | cut -c16-23)
  cd $DIR/..
  sudo sed -i "s/\(BUILD_DIGEST *= *\).*/\1$image_digest/" .env
  echo "...shutdown docker image..."
  sudo docker-compose -f $DOCKER_SCRIPT down
  echo "...clean up dangling images..."
  docker rmi $(docker images -f dangling=true -q)
  # Migration should be executed only for development
  # sudo docker-compose -f $DOCKER_SCRIPT run -T --rm web rake db:migrate
  echo "...start docker image..."
  sudo docker-compose -f $DOCKER_SCRIPT up -d
fi

echo "Completed script."

#!/bin/sh

PORT="${PORT:=3000}"

echo ">>> LTI broker starting on port: $PORT"

if [ "$RAILS_ENV" = "production" ]; then
  # Parse Rails DATABASE and REDIS urls to get host and port.
  TXADDR=${DATABASE_URL/*:\/\/}
  TXADDR=${TXADDR/*@/}
  TXADDR=${TXADDR/\/*/}
  IFS=:; set - $TXADDR; IFS=' '
  PGHOST=${1}
  PGPORT=${2:-5432}

  echo ">>> Connecting to Postgres on $PGHOST:$PGPORT"
  while ! nc -zw3 $PGHOST $PGPORT 2> /dev/null 1>&2
  do
    echo -n '.'
    sleep 1
  done
  echo
  echo "Connected to Postgres!"

  TXADDR=${REDIS_URL/*:\/\/}
  TXADDR=${TXADDR/*@/}
  TXADDR=${TXADDR/\/*/}
  IFS=:; set - $TXADDR; IFS=' '
  RDHOST=${1}
  RDPORT=${2:-6379}

  echo ">>> Connecting to Redis on $RDHOST:$RDPORT"
  while ! nc -zw3 $RDHOST $RDPORT 2> /dev/null 1>&2
  do
    echo -n '.'
    sleep 1
  done
  echo
  echo "Connected to Redis!"
fi

db_create=$(RAILS_ENV=$RAILS_ENV bundle exec rake db:create)
echo $db_create

if [ "$db_create" = "${db_create%"already exists"*}" ]; then
  echo ">>> Database migration"
  bundle exec rake db:migrate
else
  echo ">>> Database initialization"
  bundle exec rake db:schema:load
fi

echo "Start app..."
bundle exec rails s -b 0.0.0.0 -p $PORT

#!/bin/sh

if [ "$RAILS_ENV" = "production" ] && [ "$DB_ADAPTER" = "postgresql" ]; then
  while ! curl http://$DB_HOST:-localhost:${DB_PORT:-5432}/ 2>&1 | grep '52'
  do
    echo "Waiting for postgres to start up ..."
    sleep 1
  done
fi

db_create=$(RAILS_ENV=$RAILS_ENV bundle exec rake db:create)
echo $db_create

if [[ $db_create == *"ERROR"* ]]; then
  echo ">>> Database migration"
  bundle exec rake db:migrate
else
  echo ">>> Database initialization"
  bundle exec rake db:schema:load
  bundle exec rake db:seed
fi

# Assets are precompiled on start because the root can change based on ENV["RELATIVE_URL_ROOT"]
echo "Precompile assets..."
bundle exec rake assets:precompile --trace

echo "Start app..."
bundle exec rails s -b 0.0.0.0 -p 3000

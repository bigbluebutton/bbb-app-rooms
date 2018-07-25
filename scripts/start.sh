#!/bin/bash

while ! curl http://${DB_HOST:-localhost}:${DB_HOST:-5432}/ 2>&1 | grep '52'
do
  echo "Waiting for postgres to start up ..."
  sleep 1
done

# Precompile assets
#    assets are precompiled on start because the root can change based on ENV["RELATIVE_URL_ROOT"]
bundle exec rake assets:precompile --trace
# Database migrations
bundle exec rake db:exists && bundle exec rake db:migrate || bundle exec rake db:setup
# App starts
bundle exec rails s -b 0.0.0.0 -p 3000

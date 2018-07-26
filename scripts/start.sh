#!/bin/bash

while ! pg_isready -h ${DB_HOST:-localhost} -p ${DB_PORT:-5432} > /dev/null 2> /dev/null;
do
    echo "Connecting to ${DB_HOST:-localhost} failed..."
    sleep 1
done

# Assets are precompiled on start because the root can change based on ENV["RELATIVE_URL_ROOT"]
echo "Precompile assets..."
bundle exec rake assets:precompile --trace

echo "Database migrations..."
bundle exec rake db:exists && bundle exec rake db:migrate || bundle exec rake db:setup

echo "Start app..."
bundle exec rails s -b 0.0.0.0 -p 3001

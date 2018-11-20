#!/bin/bash

while ! pg_isready -h ${DB_HOST:-localhost} -p ${DB_PORT:-5432} > /dev/null 2> /dev/null;
do
    sleep 1
done
echo "Database ${DB_HOST:-localhost} started..."

# Assets are precompiled on start because the root can change based on ENV["RELATIVE_URL_ROOT"]
echo "Precompile assets..."
bundle exec rake assets:precompile --trace

echo "Database migrations..."
if bundle exec rake db:exists; then
    echo "Database already exists..."
    bundle exec rake db:migrate
else
    echo "Database does not exist..."
    bundle exec rake db:create
    bundle exec rake db:migrate
    bundle exec rake db:seed
fi

echo "Start app..."
bundle exec rails s -b 0.0.0.0 -p 3400

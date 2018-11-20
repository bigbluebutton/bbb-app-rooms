#!/bin/bash

# Assets are precompiled on start because the root can change based on ENV["RELATIVE_URL_ROOT"]
echo "Precompile assets..."
bundle exec rake assets:precompile --trace

if [ -z ${DB_ADAPTER+x} ]; then
    echo "DB_ADAPTER not included, sqlite will be assumed"
elif [ ${DB_ADAPTER} == 'postgresql' ]; then
    echo "DB_ADAPTER is ${DB_ADAPTER}, make sure the DB is up";

    echo "Database ${DB_HOST:-localhost} starting..."
    while ! pg_isready -h ${DB_HOST:-localhost} -p ${DB_PORT:-5432} > /dev/null 2> /dev/null;
    do
        sleep 1
    done
fi
echo "Database ${DB_HOST:-localhost} up and running..."
if ! bundle exec rake db:exists; then
    echo "Create the database..."
    bundle exec rake db:create
fi
echo "Database migrations..."
bundle exec rake db:migrate db:seed

echo "Start app..."
bundle exec rails s -b 0.0.0.0 -p 3400

# Base image:
FROM ruby:2.5.1

# app dependencies
RUN apt-get update -qq && apt-get install -f -y build-essential libpq-dev nodejs postgresql-client

ENV RAILS_ENV=production

ENV APP_HOME=/usr/src/app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# Add the app
ADD . $APP_HOME

# Install app dependencies
RUN bundle install --without development test doc --deployment --clean

# Precompile assets
#    assets are precompiled in runtime because RELATIVE_URL_ROOT can be set up threough .env

CMD /usr/src/app/scripts/start.sh

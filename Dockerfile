FROM ruby:2.7.0-alpine

USER root

RUN apk update \
  && apk upgrade \
  && apk add --update --no-cache \
    build-base curl-dev git postgresql-dev sqlite-libs sqlite-dev \
    yaml-dev zlib-dev nodejs yarn dumb-init

ARG BUILD_NUMBER
ENV BUILD_NUMBER=${BUILD_NUMBER}

ARG RAILS_ENV
ENV RAILS_ENV=${RAILS_ENV:-production}

ENV APP_HOME /usr/src/app
RUN mkdir -p $APP_HOME
COPY . $APP_HOME
WORKDIR $APP_HOME

ENV BUNDLER_VERSION='2.1.4'
RUN gem install bundler --no-document -v '2.1.4'
RUN if [ "$RAILS_ENV" == "production" ]; \
  then bundle config set without 'development test doc'; \
  else bundle config set without 'test doc'; \
  fi
RUN bundle install

RUN bundle update --bundler 2.1.4
RUN gem update --system

EXPOSE 3000

# Precompile assets
#   The assets are precompiled in runtime because RELATIVE_URL_ROOT can be set up through .env

# Run startup command
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["scripts/start.sh"]

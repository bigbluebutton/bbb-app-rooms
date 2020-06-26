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

ARG RELATIVE_URL_ROOT
ENV RELATIVE_URL_ROOT=${RELATIVE_URL_ROOT:-apps}

ARG APP_THEME
ENV APP_THEME=${APP_THEME}

ENV APP_HOME /usr/src/app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/

ENV BUNDLER_VERSION='2.1.4'
RUN gem install bundler --no-document -v '2.1.4'
RUN if [ "$RAILS_ENV" == "production" ]; \
  then bundle config set without 'development test doc'; \
  else bundle config set without 'test doc'; \
  fi
RUN bundle install

RUN bundle update --bundler 2.1.4
RUN gem update --system

COPY . $APP_HOME

RUN if [ "$RAILS_ENV" == "production" ]; \
  then SECRET_KEY_BASE=`bin/rake secret` bundle exec rake assets:precompile --trace; \
  fi

EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["scripts/start.sh"]

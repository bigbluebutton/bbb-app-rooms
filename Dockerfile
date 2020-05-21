FROM ruby:2.7.0-alpine

USER root

RUN apk update \
&& apk upgrade \
&& apk add --update --no-cache \
build-base curl-dev git postgresql-dev \
yaml-dev zlib-dev nodejs yarn

ENV APP_HOME /usr/src/app
RUN mkdir -p $APP_HOME
COPY . $APP_HOME
WORKDIR $APP_HOME

ENV BUNDLER_VERSION='2.1.4'
RUN gem install bundler --no-document -v '2.1.4'
RUN bundle install

RUN bundle update --bundler 2.1.4
RUN gem update --system

# Run startup command
CMD bundle exec rails server -b 0.0.0.0

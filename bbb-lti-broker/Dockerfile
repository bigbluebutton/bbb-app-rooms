FROM ruby:2.7.0

USER root

RUN apt-get update && apt-get install -y \
    postgresql-client \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt install -y nodejs

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

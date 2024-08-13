FROM alpine:3 as alpine

ARG RAILS_ROOT=/usr/src/app
ENV RAILS_ROOT=${RAILS_ROOT}

USER root
WORKDIR $RAILS_ROOT

FROM alpine as base
RUN apk add --no-cache \
    libpq \
    libxml2 \
    libxslt \
    libstdc++ \
    ruby \
    ruby-irb \
    ruby-bigdecimal \
    ruby-bundler \
    ruby-json \
    ruby-rake \
    ruby-dev \
    nodejs npm yarn \
    tini \
    tzdata \
    gettext \
    imagemagick \
    shared-mime-info \
    libffi-dev

FROM base as builder
RUN apk add --update --no-cache \
    build-base \
    libxml2-dev \
    libxslt-dev \
    pkgconf \
    postgresql-dev \
    yaml-dev \
    zlib-dev \
    curl-dev git \
    && ( echo 'install: --no-document' ; echo 'update: --no-document' ) >>/etc/gemrc
COPY . ./
RUN bundle config build.nokogiri --use-system-libraries \
    && bundle config set --local deployment 'true' \
    && bundle config set --local without 'development:test' \
    && bundle install -j4 \
    && rm -rf vendor/bundle/ruby/*/cache \
    && find vendor/bundle/ruby/*/gems/ \( -name '*.c' -o -name '*.o' \) -delete
RUN yarn install --check-files

FROM base as application
RUN apk add --no-cache \
    bash \
    postgresql-client
ARG RAILS_ENV
ENV RAILS_ENV=${RAILS_ENV:-production}
ARG BUILD_NUMBER
ENV BUILD_NUMBER=${BUILD_NUMBER}
COPY --from=builder /usr/src/app ./

FROM application
ARG PORT
ENV PORT=${PORT:-3000}
EXPOSE ${PORT}

# Create the log directory
RUN mkdir -p /usr/src/app/log

# Set the correct permissions for the log directory
RUN chmod -R 755 /usr/src/app/log

# Precompile assets
RUN SECRET_KEY_BASE=1 RAILS_ENV=${RAILS_ENV:-production} RELATIVE_URL_ROOT=${RELATIVE_URL_ROOT:-apps} bundle exec rake assets:precompile --trace

# Run startup command
CMD ["scripts/start.sh"]

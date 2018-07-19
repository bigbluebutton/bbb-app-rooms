# lti_tool_provider
Generic LTI tool_provider

# LTI Tool Provider Using ims-lti Gem

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

This is a basic and simple LTI Tool Provider based on https://github.com/instructure/lti_tool_provider_example that uses the
[ims-lti](https://github.com/instructure/ims-lti) 2.0.0.beta gem. It includes a simple Tool that is enabled by default, but it
also allows to enable external applications to be hocked as Tools while acting as a broker for them

To get this running in your development environment, check out the repo then:

    bundle install
    bundle exec rake db:create
    bundle exec rake db:migrate
    bundle exec rake db:seed
    bundle exec rails s

To get this running with Docker, follow these steps:

  $ cp docker-compose/config/* config/
  $ docker-compose build
  $ docker-compose run --rm lti-test-tool bundle install
  $ docker-compose run --rm lti-test-tool bundle exec rake db:create
  $ docker-compose run --rm lti-test-tool bundle exec rake db:migrate
  $ docker-compose run --rm lti-test-tool bundle exec rake db:seed
  $ docker-compose up

You can add the tool to a tool consumer with the the '/tool_proxy' endpoint

To customise its behaiviour copy the file dotenv as .env (for development only) and uncomment the environment variables as required.

For using a different postgres server
```
 # Database configuration
 # DB_HOST=
 # DB_USERNAME=
 # DB_PASSWORD=
```
For changing the root (this is mandatory if you run the Tool Provider in the same box where BigBlueButton is running) and also
for making use of the brokerage capability the external Application(s) has(ve) to be declared in the environment variable
```
 # LTI Broker configuration
 # It defines the root where the application is being mounted (e.g. lti for http://hostname/lti or lti/tools for http://hostname/lti/tools)
 # RELATIVE_URL_ROOT=lti
 # It defines the external application to be used by default as for serving LTI launch requests
 # DEFAULT_TOOL=default
```

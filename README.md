# bbb_lti_broker
Generic LTI tool_provider

# LTI Tool Provider Using ims-lti Gem

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

This is a basic and simple LTI Tool Provider based on https://github.com/instructure/lti_tool_provider_example that uses the
[ims-lti](https://github.com/instructure/ims-lti) 2.0.0.beta gem. It includes a simple Tool that is enabled by default, but it
also allows to enable external applications to be hocked as Tools while acting as a broker for them

To get this running in your development environment, check out the repo then:

```
  gem i bundler -v 1.17.3
  bundle install
  bundle exec rake db:create
  bundle exec rake db:migrate
  bundle exec rake db:seed
  bundle exec rails s
```

To get this running with Docker, follow these steps:

```
  cp docker-compose/config/* config/
  docker-compose build
  docker-compose run --rm lti-test-tool bundle install
  docker-compose run --rm lti-test-tool bundle exec rake db:create
  docker-compose run --rm lti-test-tool bundle exec rake db:migrate
  docker-compose run --rm lti-test-tool bundle exec rake db:seed
  docker-compose up
```

You can add the tool to a tool consumer with the the '/tool_proxy' endpoint

To customize its behaviour copy the file dotenv as .env (for development only) and uncomment the environment variables as required.

The database by default is sqlite3, even for production. Change the adapter for using postgresql and set up the rest of the parameters.

```
  # DB_ADAPTER=[sqlite3|postgresql]
  # DB_HOST=<localhost>
  # DB_NAME=
  # DB_USERNAME=<root>
  # DB_PASSWORD=
```

For changing the root (this is mandatory if you run the Tool Provider in the same box where BigBlueButton is running) and also
for making use of the brokerage capability the external Application(s) must be declared in environment variables.

```
  # App configuration
  # Define the root where the application is being mounted
  # (e.g. lti for http://example.com/lti or lti/tools for http://example.com/lti/tools)
  # RELATIVE_URL_ROOT=lti

  # LTI tools configuration
  # Define the external application to be used by default as for serving LTI launch requests.
  # DEFAULT_LTI_TOOL=<default|rooms>
```

Whitelist the URL that the broker is on

```
  # DEVELOPER_MODE_ENABLED=broker.example.com
```

There are some functions that can be enabled when setting the server into developer mode.
This includes:
  - A LTI App can be used by default for testing purposes.
  - A UI for managing OAuth2 applications is enabled [http://example.com/lti/oauth/applications].

```
  # DEVELOPER_MODE_ENABLED=true
```

The seed will set up data by default that should be changed for production. This is:
  - LTI key pair
```
  {
    :key => 'key',
    :secret => 'secret'
  }
```
  - LTI Tool specific for https://github.com/bigbluebutton/bbb-app-rooms
```
  {
    :name => 'rooms',
    :uid => 'b21211c29d2720a4c847fc3a9097720a196f7fafddbaa0f68d5c1cb54fdbb046',
    :secret => '3590e00d7ebd398b75c4ea5a65097a19a687d72715af811bc8b3e78aa1664789',
    :redirect_uri => 'http://example.com/apps/rooms/auth/ltibroker/callback'
  }
```
Where name is the application key (keep it short, 'rooms' is the identifier for bbb-app-rooms). uid and secret have to be used for OAuth2 when configuring the tool. And redirect_url holds the callback url for the application. As the app uses a gem that implements an omniauth strategy (see bbb-app-rooms documentation) you should keep it in the format expressed in the example.

```
  <scheme>://<hostname>/<root for the app>/<key for the app>/<omniauth callback>
```

For changing the seeded data or adding keys and apps manually, there are some rake tools provided.

```
  rake db:apps:showall
  rake db:apps:update[rooms,https://newexample.com/apps]
```

For adding an LTI 1.3 registration, there are some rake commands (for production) and a web UI for development mode.

```
  http://broker.example.com/lti/registration/list
```
```
  rake db:registration:new[key]
  rake db:registration:keygen[key]
```

Use rake --tasks for seeing all the options available

To set the default room settings, use the custom parameters:

```
record=true
wait_moderator=true
all_moderators=true
```

They correspond to turn recording on, wait for moderator to start the meeting, and allow all users to join as a moderator.
## BigBlueButton LTI Broker
The BBB LTI Broker is a Web Application that acts as a LTI Broker for connecting tool consumers with BigBlueButton Apps. 

## Getting Started
#### Use Docker
First, make sure you have both Docker and Docker-Compose installed as they are requirements.

Then, to get this running with Docker, follow these steps:
Pull the ```docker-compose.yml``` and ```dotenv``` files from the repository. Then run the following commands.
```
  docker-compose run app rake db:create
  docker-compose run app rake db:migrate
  docker-compose run app rake db:seed
  docker-compose up
```
To customize its behaviour copy the file dotenv as app.env (for development only) and uncomment the environment variables as required.

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

## Ports
The LTI Broker uses port 3000 by default, but this can be changed by editing the docker-compose file.
Under the 'app' service the 'ports' configuration can be modified from 3000:3000 to DESIRED_PORT:3000

## Add a Tool to the LTI Broker
In order to add an LTI Tool Provider or edit an existing tool, rake commands are used.
A name for the tool, the hostname, as well as the provided UID and secret from the tool are required.
The command is ```docker-compose run app rake "db:apps:add[tool_name,hostname,tool_uid,tool_secret]"```

#### Useful Rake Commands
Rake commands should be run using the following syntax:
```
docker-compose run app rake "RAKE_COMMAND"
```
The following are some useful and relevant rake commands for the LTI Broker:
* rake db:apps:add[name,hostname,uid,secret,root]  # Add a new blti app
* rake db:apps:delete[name]                        # Delete an existent blti app if exists
* rake db:apps:deleteall                           # Delete all existent blti apps
* rake db:apps:show[name]                          # Show an existent blti app if exists
* rake db:apps:showall                             # Show all existent blti apps
* rake db:apps:update[name,hostname,uid,secret]    # Update an existent blti app if exists
* rake db:create                                   # Creates the database from DATABASE_URL or config/database.yml for the curre...
* rake db:drop                                     # Drops the database from DATABASE_URL or config/database.yml for the current...
* rake db:environment:set                          # Set the environment value for the database
* rake db:exists                                   # Checks to see if the database exists
* rake db:fixtures:load                            # Loads fixtures into the current environment's database
* rake db:keys:add[keys]                           # Add a new blti keypair (e.g
* rake db:keys:delete[keys]                        # Delete an existent blti keypair if exists (e.g
* rake db:keys:deleteall                           # Delete all existent blti keypairs
* rake db:keys:show                                # Show all existent blti keypairs
* rake db:keys:update[keys]                        # Update an existent blti keypair if exists (e.g
* rake db:migrate                                  # Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog)
* rake db:migrate:status                           # Display status of migrations
* rake db:prepare                                  # Runs setup if database does not exist, or runs migrations if it does
* rake db:registration:delete                      # Delete existing Tool configuration
* rake db:registration:keygen[type]                # Generate new key pair for existing Tool configuration [key, jwk]
* rake db:registration:new[type]                   # Add new Tool configuration [key, jwk]


## Link the LTI Broker to LMS

### Using LTI 1.0/1.1
There is no need to register an LTI 1.0/1.1 tool with the broker. All that the the LTI Tool Consumer needs is the Broker Key and Secret. These can be set as environment variables. 
There are certain fields the tool consumer will require. These fields (and example values) are:
Tool URL => ```http://broker.example.com/lti/TOOL_NAME/messages/blti```
Consumer Key => ```BROKER_KEY```
Shared Secret => ```BROKER_SECRET```

### Using LTI 1.3
#### Add an LTI 1.3 Registration
To register an LTI 1.3 tool with the Broker, there are some rake commands (for production) and a web UI for development mode.
The Web UI is found at ```http://broker.example.com/lti/registration/list```
The rake tasks to register are: 
```
rake db:registration:new[key]
rake db:registration:keygen[key]
```
In order to see all the available options use ```rake --tasks```

#### Using the Web UI
Navigate to ```http://broker.example.com/lti/registration/list```


Once the LTI 1.3 tool is registered with the Broker, it can be hooked into a tool consumer.
There are certain fields the tool consumer will require. These fields (and example values) are:
Tool URL => ```http://broker.example.com/lti/TOOL_NAME/messages/oblti```
Client ID => ```Gh4Bj81cK290d```
Public Key => ```A_JWT_KEY```
Initiate Login URL => ```http://broker.example.com/lti/TOOL_NAME/auth/login```
Redirection URI(s) => 
```
http://broker.example.com/lti/TOOL_NAME/messages/oblti
http://broker.example.com/lti/TOOL_NAME/messages/deep-link
```

All of these fields and values are visible and provided in the web UI.
The other empty fields in the web UI are the following: Key Set URL, Auth Token URL, and Auth Login URL

These values will be provided by your LMS after you have registered the tool provider.


## Developer Notes
Must set DOCKER_USERNAME and DOCKER_PASSWORD in CircleCI config in order to have new images automatically pushed to dockerhub.
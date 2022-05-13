<h1>How to deploy the Rooms Tool with the LTI Broker localy</h1>
This is a tutorial for a local deployment of the rooms and broker apps as well as setting it up with moodle (or any other LMS). 

### Prerequisites:
- Install [nginx](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#prebuilt_ubuntu) and [postgresql](https://computingforgeeks.com/install-postgresql-11-on-ubuntu-linux/) on your machine 
- Install [ruby on rails](https://gorails.com/setup/ubuntu/16.04)
- [Set up a domain](https://github.com/jfederico/bbb-lti-run#preliminary-steps)
- [Install moodle](https://docs.moodle.org/39/en/Step-by-step_Installation_Guide_for_Ubuntu) (I did this in a separate lxc container) or any other LMS

### Repo Setup:

1. Clone the two repositories: [bbb-app-rooms](https://github.com/bigbluebutton/bbb-app-rooms) and [bbb-lti-broker](https://github.com/bigbluebutton/bbb-lti-broker)

2. Set up the environment variables for the rooms app: <br>
`$ cd bbb-app-rooms` <br>
`$ cp dotenv .env` <br>
`$ sudo vi .env` <br>
Edit the following variable values as necessary: <br>
```
## App configuration
# Generate a secret by running the command openssl rand -hex 32
SECRET_KEY_BASE=

RELATIVE_URL_ROOT=apps

## Database configuration
# DB_ADAPTER=[postgresql]
# DB_HOST=<localhost>
# DB_NAME=
# DB_USERNAME=<root>
# DB_PASSWORD=

# BigBlueButton configuration
BIGBLUEBUTTON_ENDPOINT=https://bbb.<your-name>.blindside-dev.com/bigbluebutton/api
BIGBLUEBUTTON_SECRET=<your server's secret>
BIGBLUEBUTTON_MODERATOR_ROLES=Instructor,Faculty,Teacher,Mentor,Administrator,Admin

# BigBlueButton LTI Broker configuration
OMNIAUTH_BBBLTIBROKER_SITE=https://lti.<JOHN>.blindside-dev.com
OMNIAUTH_BBBLTIBROKER_ROOT=lti
#  Should match the values used when adding the app to the broker.
#    rake db:apps:add[rooms,key,secret,https://lti.<JOHN>.blindside-dev.com/apps/rooms/auth/bbbltibroker/callback]
OMNIAUTH_BBBLTIBROKER_KEY=<choose a key>
OMNIAUTH_BBBLTIBROKER_SECRET=<choose a secret>

## Set the hostname using your own domain (Required)
URL_HOST=lti.<JOHN>.blindside-dev.com

## Use to send logs to Standard Output (Optional)
RAILS_LOG_TO_STDOUT=true

## Use to serve assets through the app (Required for now)
RAILS_SERVE_STATIC_FILES=true

## Use to enable features only available for development (Optional)
# RAILS_ENV=production
```
3. Set up the environment variables for the lti broker:
`$ cd ~/bbb-lti-broker` <br>
`$ cp dotenv .env` <br>
`$ sudo vi .env` <br>
```
POSTGRES_PASSWORD=<password you set for the postgres database during setup>
POSTGRES_USER=postgres

# Create a Secret Key for Rails
#
# You can generate a secure one through the Greenlight docker image
# with the command.
#
#   docker run --rm bigbluebutton/bbb-app-rooms:latest bundle exec rake secret
#
SECRET_KEY_BASE=

# App configuration
RELATIVE_URL_ROOT=lti

# LTI tools configuration
# DEFAULT_LTI_TOOL=rooms

# DEVELOPER_MODE_ENABLED=true

#WHITELIST_HOST=broker.example.com

## Set the hostname using your own domain (Required)
URL_HOST=lti.<JOHN>.blindside-dev.com

## Use only with postgres instance outside the one pre-packaged with docker-compose (Optional)
# DATABASE_URL=postgres://postgres:password@localhost

## Use to send logs to Standard Output (Optional)
RAILS_LOG_TO_STDOUT=true

## Use to serve assets through the app (Required for now)
RAILS_SERVE_STATIC_FILES=true

## Use to enable features only available for development (Optional)
#RAILS_ENV=development
```
4. Create, migrate and seed the databases for both the rooms and broker (`rake db:create db:migrate db:seed`) <br>

5. Add the rooms app to the broker. For key and secret, use the ones you set in the rooms app env variables: \
    `$ rake db:apps:add[rooms,https://lti.<JOHN>.blindside-dev.com/apps/rooms/auth/bbbltibroker/callback,<key>,<secret>]` <br>
    Add the key and secret to the keyset: <br>
    `$ rake db:keys:add[<key>:<secret>]`

### NGINX Configuration
6. Configure nginx. 
    - Edit the conf file for nginx: <br>
    `$ sudo vim /etc/nginx/conf.d/default.conf`
    - Replace the contents using [this template](https://github.com/jfederico/bbb-lti-run/blob/master/nginx/.sites.template.local) <br>
    - Run `$ sudo systemctl restart nginx`<br>

### Adding the tool to an LMS

7. Run both applications: 
    - From the bbb-app-rooms directory, run `$ rails s -b 0.0.0.0 -p 3012` <br>
    - From the bbb-lti-broker directory, run `$ rails s -b 0.0.0.0 -p 3011` <br>

8. In your browser, go to lti.\<JOHN>.blindside-dev.com\lti 

9. Click on 'View LTI Configuration XML'. It'll take to you a page with the following URL: https://lti.\<JOHN>.blindside-dev.com/lti/default/xml_config. Replace the 'default' with 'rooms' and refresh the page/press enter. 

10. Copy the secure_launch_url. This is the url that you will use when adding the plugin in your lms. The consumer_key and shared_secret are the same as the ones set in the rooms env. variables (as OMNIAUTH_BBBLTIBROKER_KEY and OMNIAUTH_BBBLTIBROKER_SECRET)  

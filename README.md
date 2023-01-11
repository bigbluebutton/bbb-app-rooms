<h1>How to deploy the LTI Rooms Tool with the LTI Broker locally</h1>
This is a tutorial for a local deployment of the rooms and broker apps as well as setting it up with moodle (or any other LMS).

## Prerequisites
In order to successfully run the LTI applications, you must have the following prerequisites:
- A BigBlueButton server 
- A domain name
- A learning management system (admin privileges are required in order to add the application as an external tool)
- [Docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04) and [Docker-compose](https://docs.docker.com/compose/install/linux/) installed


# Setup & Run

You have two options for running the LTI applications: 
1. [Using DockerHub Images.](##-Option-1:-Use-DockerHub-Images)
2. [Cloning the repositories for GitHub.](##-Option-2:-Cloning-the-Repos-from-GitHub-(for-development))

If you simply want to run the application, go with option 1. Option 2 is for development purposes. 


In both cases, you will need to first clone and setup [bbb-lti-run](https://github.com/jfederico/bbb-lti-run).


## Setting up bbb-lti-run
1. Clone the repo
 ```
git clone git@github.com:blindsidenetworks/bbb-lti-run.git
cd bbb-lti-run
```


2. Edit the `.env` file located in the root of the project


```
cp dotenv .env
vi .env
```


Set `HOST_NAME` to your domain name (the deployment endpoint). For example, ``` https://lti.<JOHN>.blindside-dev.com/ ```


### Generating LetsEncrypt SSL Certificate Manually


Create your own SSL Letsencrypt certificates. If you are going to
have this deployment running on your own computer (or in a private VM), you
need to generate the SSL certificates with certbot manually by adding the
challenge to your DNS.


Install letsencrypt in your own computer


```
sudo apt-get update
sudo apt-get -y install letsencrypt
```


Make yourself root


```
sudo -i
```


Start creating the certificates


```
certbot certonly --manual -d lti.<JOHN>.blindside-dev.com --agree-tos --no-bootstrap --manual-public-ip-logging-ok --preferred-challenges=dns --email hostmaster@blindside-dev.com --server https://acme-v02.api.letsencrypt.org/directory
```


You will see something like this
```
-server https://acme-v02.api.letsencrypt.org/directory
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator manual, Installer None
Obtaining a new certificate
Performing the following challenges:
dns-01 challenge for gl.<JOHN>.blindside-dev.com
dns-01 challenge for gl.<JOHN>.blindside-dev.com


- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.gl.<JOHN>.blindside-dev.com with the following value:


2dxWYkcETHnimmQmCL0MCbhneRNxMEMo9yjk6P_17kE


Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
```


Create a TXT record in your DNS for
`_acme-challenge.lti.<JOHN>.blindside-dev.com` with the challenge string as
its value `2dxWYkcETHnimmQmCL0MCbhneRNxMEMo9yjk6P_17kE`


Copy the certificates to your bbb-lti-run directory. Although `/etc/letsencrypt/live/`
holds the latest certificate, they are only symbolic links. The real files must be copied too.


```
cd bbb-lti-run
mkdir -p data/certbot/conf/archive
mkdir -p data/certbot/conf/live
cp -R /etc/letsencrypt/archive/lti.<JOHN>.blindside-dev.com <YOUR ROOT>/bbb-lti-run/data/certbot/conf/archive
cp -R /etc/letsencrypt/live/lti.<JOHN>.blindside-dev.com <YOUR ROOT>/bbb-lti-run/data/certbot/conf/live
```


Yay! You've set up bbb-lti-run. Now, you have 2 options for how to run the LTI apps:
    
1. [By pulling the images from DockerHub](#Option-1:-Use-DockerHub-Images)

2. [By cloning the repos from GitHub (this setup is for development)](#Option-2:-Cloning-the-Repos-from-GitHub-(for-development))


## Option 1: Use DockerHub Images
1. In the .env file located at the root of bbb-lti-run:
    -  Optionally, set the `DOCKER_REPO` environment variable to the repo from which you would like to pull the images ('bigbluebutton' is the default if this variable isn't set)
    -  Optionally, set the `DOCKER_TAG` environment variable to the tag of the images you'd like to pull ('latest' is the default if this variable isn't set)
        
2. Set the environment variables for broker and rooms:
    * Edit the `broker/.env` file and replace the following default values.


        ```
        cp broker/dotenv broker/.env
        vi broker/.env
        ```


        | Variable | Description |
        | --------- | --------- |
        | **SECRET_KEY_BASE** | This is the Ruby On Rails secret key and must be replaced with a random one. You can generate a suitable secret using `openssl rand -hex 32`. |
        | **RELATIVE_URL_ROOT** | This is the root of the project (ex. 'lti') |
        | **DEFAULT_LTI_TOOL** | This one is used to set the default tool (currently the only tool available is rooms) |
        | **URL_HOST** | Your domain name |
        | **DATABASE_URL** | The URL of the database you are using (only set this if you are using a database outside of bbb-lti-run's postgres instance) |




    * Edit the `rooms/.env` file and replace the following default values.


                ```
                cp rooms/dotenv rooms/.env
                vi rooms/.env
                ```


        | Variable | Description |
        | --------- | --------- |
        | **SECRET_KEY_BASE** | This is the Ruby On Rails secret key and must be replaced with a random one. You can generate a suitable secret using `openssl rand -hex 32`. |
        | **RELATIVE_URL_ROOT** | The relative root for Rooms, it is required as is (for now), and it is by default set to `apps` |
        | **BIGBLUEBUTTON_ENDPOINT** | The BigBlueButton Endpoint to the server linked to this application. |
        | **BIGBLUEBUTTON_SECRET** | The BigBlueButton Secret (this can be found by running `bbb-conf --secret` in the BBB server)  |                  
        | **BIGBLUEBUTTON_MODERATOR_ROLES** | Specify which roles should be considered moderators in a BigBlueButton meeting. For example, Instructor,Faculty,Teacher,Mentor,Administrator,Admin |
        | **OMNIAUTH_BBBLTIBROKER_SITE** | Should match the values set up for the broker URL_HOST
        | **OMNIAUTH_BBBLTIBROKER_ROOT** | Should match the values set up for the broker RELATIVE_URL_ROOT
        | **OMNIAUTH_BBBLTIBROKER_KEY** and **OMNIAUTH_BBBLTIBROKER_SECRET** | Choose whichever values you like for these. We will use the same values later in step 6 when adding the rooms app as a tool in the broker. |
        | **DATABASE_URL** | The URL of the database you are using (only set this if you are using a database outside of bbb-lti-run's postgres instance) |


3. In the bbb-lti-run root directory (`cd <your root>/bbb-lti-run`), start the environment with the the command `docker compose up` (or `docker-compose up`, depending on your docker compose version)


4. To test that the set up was successful once all the containers are running, visit the url you configured for your HOST_NAME. For ex.  ``` https://lti.<JOHN>.blindside-dev.com/ ``` . You will be taken to the BBB LTI Broker site. 




5. Now, it is time to add the rooms app as a tool in the broker. To do so, you'll need your **URL_HOST** and the following variables that you set in bbb-lti-run's rooms/.env file: 
**RELATIVE_URL_ROOT** , **OMNIAUTH_BBBLTIBROKER_KEY**, **OMNIAUTH_BBBLTIBROKER_SECRET**. Run the following commands with your respective values:
        
    ```
    docker exec -t broker bundle exec rake db:keys:add[<OMNIAUTH_BBBLTIBROKER_KEY>,<OMNIAUTH_BBBLTIBROKER_KEY>]
    
    docker exec -t broker bundle exec rake db:apps:add[rooms,<URL_HOST>/<RELATIVE_URL_ROOT>/rooms/auth/bbbltibroker/callback, <OMNIAUTH_BBBLTIBROKER_KEY>,<OMNIAUTH_BBBLTIBROKER_KEY>]
    ```
        
    For example, if your values were:
    
    ```
    URL_HOST=https://lti.JOHN.blindside-dev.com
    RELATIVE_URL_ROOT=apps
    OMNIAUTH_BBBLTIBROKER_KEY=exampleKey
    OMNIAUTH_BBBLTIBROKER_SECRET=exampleSecret
    ```
       
    then you would run the following commands:
    
    ```
    docker exec -t broker bundle exec rake db:keys:add[examplekey,exampleSecret]
    docker exec -t broker bundle exec rake db:apps:add[rooms,https://lti.JOHN.blindside-dev.com/apps/rooms/auth/bbbltibroker/callback, exampleKey,exampleSecret]
    ```


6. Yay! Now you're ready to [add the rooms app to your LMS](#Configure-the-Rooms-app-in-your-LMS)!




## Option 2: Cloning the Repos from GitHub (for development)
There are 2 additional repos you will need in order to run LTI:
- [bbb-app-rooms](https://github.com/bigbluebutton/bbb-app-rooms): this application serves as the user interface for providing BigBlueButton rooms through LTI.
- [bbb-lti-broker](https://github.com/bigbluebutton/bbb-lti-broker): The BBB LTI Broker is a Web Application that acts as a LTI Broker for connecting Tool Consumers with BigBlueButton Tools.


1. After cloning the two repos, edit the .env files in each and replace the default values. 

    For the Broker: 
   
    ```
    cp bbb-lti-broker/dotenv bbb-lti-broker/.env
    vi .env
    ```


    | Variable | Description |
    | --------- | --------- |
    | **SECRET_KEY_BASE** | This is the Ruby On Rails secret key and must be replaced with a random one. You can generate a suitable secret using `openssl rand -hex 32`. |
    | **RELATIVE_URL_ROOT** | This is the root of the project (ex. 'lti') |
    | **DEFAULT_LTI_TOOL** | This one is used to set the default tool (currently the only tool available is rooms) |
    | **URL_HOST** | Your domain name |
    | **DATABASE_URL** | The URL of the databse you are using (if you are following this guide exactly, this would be the database URL of the postgres docker container from bbb-lti-run). For example, `postgresql://postgres:password@<your ip>:5432` |


    For Rooms:
    ```
    cp bbb-app-rooms/dotenv bbb-app-rooms/.env
    vi .env
    ```

    | Variable | Description |
    | --------- | --------- |
    | **SECRET_KEY_BASE** | This is the Ruby On Rails secret key and must be replaced with a random one. You can generate a suitable secret using `openssl rand -hex 32`. |
    | **RELATIVE_URL_ROOT** | The relative root for Rooms, it is required as is (for now), and it is by default set to `apps` |
    | **BIGBLUEBUTTON_ENDPOINT** | The BigBlueButton Endpoint to the server linked to this application. |
    | **BIGBLUEBUTTON_SECRET** | The BigBlueButton Secret (this can be found by running `bbb-conf --secret` in the BBB server)  |                  
    | **BIGBLUEBUTTON_MODERATOR_ROLES** | Specify which roles should be considered moderators in a BigBlueButton meeting. For example, Instructor,Faculty,Teacher,Mentor,Administrator,Admin |
    | **OMNIAUTH_BBBLTIBROKER_SITE** | Should match the values set up for the broker URL_HOST
    | **OMNIAUTH_BBBLTIBROKER_ROOT** | Should match the values set up for the broker RELATIVE_URL_ROOT
    | **OMNIAUTH_BBBLTIBROKER_KEY** and **OMNIAUTH_BBBLTIBROKER_SECRET** | Choose whichever values you like for these. We will use the same values later in step 6 when adding the rooms app as a tool in the broker. 
        
2. Create, migrate and seed the databases for both the rooms and broker: `rake db:create db:migrate`


3. Now, it is time to add the rooms app as a tool in the broker. To do so, you'll need your **URL_HOST** and the following variables that you set in bbb-lti-run's rooms/.env file: 
**RELATIVE_URL_ROOT** , **OMNIAUTH_BBBLTIBROKER_KEY**, **OMNIAUTH_BBBLTIBROKER_SECRET**. Run the following commands with your respective values:
    ```
    rake db:apps:add[rooms,<URL_HOST>/<RELATIVE_URL_ROOT>/rooms/auth/bbbltibroker/callback, <OMNIAUTH_BBBLTIBROKER_KEY>,<OMNIAUTH_BBBLTIBROKER_KEY>]
    ```


    then, add the Add the key and secret to the keyset:
    ```
    rake db:keys:add[<OMNIAUTH_BBBLTIBROKER_KEY>,<OMNIAUTH_BBBLTIBROKER_KEY>]
    ```
         
    For example, if your values are:
    ```
    URL_HOST=https://lti.JOHN.blindside-dev.com
    RELATIVE_URL_ROOT=apps
    OMNIAUTH_BBBLTIBROKER_KEY=exampleKey
    OMNIAUTH_BBBLTIBROKER_SECRET=exampleSecret
    ```
    
    then you would run the commands:
    ```
    rake db:apps:add[rooms,https://lti.JOHN.blindside-dev.com/apps/rooms/auth/bbbltibroker/callback, exampleKey,exampleSecret]

    rake db:keys:add[<OMNIAUTH_BBBLTIBROKER_KEY>,<OMNIAUTH_BBBLTIBROKER_KEY>]
    
    ```


4. Now it is time to run the applications! 
    - From the bbb-app-rooms directory, run `rails s -b 0.0.0.0 -p 3012`
    - From the bbb-lti-broker directory, run `rails s -b 0.0.0.0 -p 3011`
    - From the bbb-lti-run directory, run `docker compose up`
        
5. To test that the set up was successful once all the containers are running, visit the url you configured for your URL_HOST. For ex.  ``` https://lti.<JOHN>.blindside-dev.com/ ``` . You will be taken to the BBB LTI Broker site. 


6. Yay! Now you're ready to [add the rooms app to your LMS](#Configure-the-Rooms-app-in-your-LMS)!


# Configure the Rooms app in your LMS
This process will depend on which LMS you are using. However, in all cases, you will need the LTI launch endpoint URL to configure your LMS. To get your LTI link, visit your broker site (ex. https://lti.JOHN.blindside-dev.com/). Then click 'config' in the top right. There, you will find the LTI launch endpoint.

The consumer_key and shared_secret are the same as the ones set in the rooms env. variables (as OMNIAUTH_BBBLTIBROKER_KEY and OMNIAUTH_BBBLTIBROKER_SECRET). When adding the tool, select LTI 1.0/1.1 (not 1.3). 

Make sure to select 'Force SSL' if your LMS provides you with that option (such as in Moodle). You may also face issues if your LMS's connection is not secure (make sure you are connecting over https).

# Additional Environment Variables
In bbb-app-rooms, you may choose to configure these additional environment variables:
| Variable | Description |
| --------- | --------- |
| **CACHE_ENABLED** | If enabled, caching will be used for optimizing requests to external servers. It is false by default. |
| **BIGBLUEBUTTON_CHECKSUM_ALGORITHM** |  SHA algorithm to use for the checksum required by the BBB API |

# Exceptions
### The DOMAIN NAME is updated after the application starts
It is important to note that if the DOMAIN NAME is updated after the application was run, the launcher will have a reference to the old domain as for the callbacks when using an external authentication system. In such cases the easiest way to overcome the issue is to recreate the database.

```
docker ps
```

Will return something like this:


```
CONTAINER ID        IMAGE                                 COMMAND                  CREATED             STATUS              PORTS                                      NAMES
2642896703a1        nginx                                 "/bin/bash -c 'envsu…"   25 minutes ago      Up 25 minutes       0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   nginx
7d1b913aad6e        bigbluebutton/bbb-app-rooms:latest    "scripts/start.sh"       25 minutes ago      Up 25 minutes       0.0.0.0:3002->3000/tcp                     rooms
b552ed1b3db6        bigbluebutton/bbb-lti-broker:latest   "scripts/start.sh"       25 minutes ago      Up 25 minutes       0.0.0.0:3001->3000/tcp                     broker
a41613dfa428        postgres:9.5-alpine                   "docker-entrypoint.s…"   25 minutes ago      Up 25 minutes       0.0.0.0:5432->5432/tcp                     postgres
```


Use the CONTAINER_ID to execute terminal commands.


```
docker exec -t broker DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:drop
docker exec -t broker DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:setup
```

It may be necessary to interrupt docker-compose and execute a
`docker compose down` and then `docker compose up` to clean up what is left
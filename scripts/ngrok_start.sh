#!/bin/bash

# Set your paths for bbb-lti-broker and bbb-app-rooms before starting
# Tip: use "$HOME" instead of "~"
lti_broker_path=../bbb-lti-broker # ex: "$HOME/Projects/bbb-lti-broker"
app_rooms_path=.  #     "$HOME/Projects/bbb-app-rooms"

my_key="my-key"
my_secret="my-secret"
my_internal_key="my-internal-key"
my_internal_secret="my-internal-secret"

greenb=`tput setaf 2; tput setab 0`
yellowb=`tput setaf 3; tput setab 0`
reset=`tput sgr0`

if [ -z $lti_broker_path ] || [ -z $app_rooms_path ];
then
  echo "Edit the script and set your paths for" \
     "${greenb}bbb-lti-broker${reset} and"\
     "${yellowb}bbb-app-rooms${reset} before starting (first 2 lines of code)."
  exit 1
fi

port0="3000"
port1="3001"

start_ngrok() {
  ngrok_log="$HOME/.ngrok2/ngrok.log"
  ngrok_is_running=false
  if [ $(ps -e | grep -Po "\s+ngrok\s*$" | wc -l) -gt 0 ];
  then
    ngrok_is_running=true
  fi

  if [ $ngrok_is_running = true ];
  then
    read -p "ngrok is running, do you want to kill it? [y/N] "  proceed
    if [ "${proceed,,}" = "y" ];
    then
      killall ngrok
    else
      echo "exiting"
      exit 1
    fi
  fi

  ngrok start --log=stdout broker rooms > $ngrok_log &

  # cat -v is used to read binary files
  # grep will search for the regex and will return anything after \K
  address0_cmd="cat -v $ngrok_log | grep -Po \"msg=\\\"started tunnel\\\".*localhost:$port0.*url=http://\K.*\.ngrok\.io\""
  address1_cmd="cat -v $ngrok_log | grep -Po \"msg=\\\"started tunnel\\\".*localhost:$port1.*url=http://\K.*\.ngrok\.io\""

  address0=$(eval $address0_cmd)
  address1=$(eval $address1_cmd)
  while [ -z $address0 ] || [ -z $address1 ];
  do
    address0=$(eval $address0_cmd)
    address1=$(eval $address1_cmd)
    echo "Waiting for ngrok to start..."
    sleep 1s
  done

  echo
  echo "ngrok started"
  echo "Forwarding: http://localhost:${greenb}$port0${reset} ->  http://${greenb}$address0${reset}"
  echo "Forwarding: http://localhost:${greenb}$port0${reset} -> https://${greenb}$address0${reset}"
  echo "Forwarding: http://localhost:${yellowb}$port1${reset} ->  http://${yellowb}$address1${reset}"
  echo "Forwarding: http://localhost:${yellowb}$port1${reset} -> https://${yellowb}$address1${reset}"
}

update_ngrok_addresses() {
  file0="$lti_broker_path/.env"
  file1="$app_rooms_path/.env"

  echo
  replace_key_value $file0 "URL_HOST" $address0 ${greenb}
  replace_key_value $file1 "URL_HOST" $address1 ${yellowb}
  replace_key_value $file1 "OMNIAUTH_BBBLTIBROKER_SITE" "https://$address0" ${yellowb}

  echo
  echo "Check if everything is alright."
  read -p "This will reset the ${greenb}bbb-lti-broker${reset} database. Proceed? [y/N] " proceed
  echo
  if [ "${proceed,,}" = "y" ];
  then
    dc_file=$lti_broker_path/docker-compose.yml
    docker-compose -f $dc_file run app bundle exec rake db:environment:set RAILS_ENV=development
    docker-compose -f $dc_file run app bundle exec rake db:reset
    docker-compose -f $dc_file run app bundle exec rake "db:keys:add[$my_key:$my_secret]"
    docker-compose -f $dc_file run app bundle exec rake "db:apps:add[tool,https://$address1/rooms/auth/bbbltibroker/callback,$my_internal_key,$my_internal_secret]"
  else
    echo "exiting"
    exit 1
  fi
}

replace_key_value() {
  file=$1
  key=$2
  addr=$3
  if [ $# -ge 4 ]
  then
    color=$4
  else
    color=''
  fi
  echo "Replacing $key=${color}$addr${reset} in ${color}$(readlink -e $file)${reset}"
  # replace '/' for '\/' in $addr
  addr=$(echo $addr | sed 's/\//\\\//g')
  # Find line starting by $key= (any space to the left of it is acceptable)
  # In this line, find all groups that does NOT contain '=', '#', ' ' or '\t'.
  # Select the group 2 and replace for $addr
  # Ex:
  # 11111111 222222222222222 ...
  # URL_HOST=abcdef.ngrok.io # SOME COMMENT
  # group 1: URL_HOST
  # group 2: abcdef.ngrok.io
  # Replace group 2 with $addr, so it becomes:
  # URL_HOST=$addr # SOME COMMENT
  sed -i "/^[\t ]*$key=/s/[\t ]*[^=#\t ]*/$addr/2" $file
}

start_ngrok
update_ngrok_addresses

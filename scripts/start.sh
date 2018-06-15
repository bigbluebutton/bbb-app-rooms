#!/bin/bash

bundle exec assets:precompile --trace
bundle exec rake db:exists && bundle exec rake db:migrate || bundle exec rake db:setup
bundle exec rails s -b 0.0.0.0 -p 3000

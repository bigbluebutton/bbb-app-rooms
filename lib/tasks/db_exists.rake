# frozen_string_literal: true

namespace :db do
  desc 'Checks to see if the database exists'
  task exists: :environment do
    Rake::Task['environment'].invoke
    ActiveRecord::Base.connection
  rescue StandardError
    puts("It doesn't exist")
    exit(1)
  else
    puts('It does exist')
    exit(0)
  end
end

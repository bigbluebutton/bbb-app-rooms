# frozen_string_literal: true

namespace :users do
  namespace :accounts do
    desc 'Add an admin account'
    task :create_admin, [:username] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      unless args[:username]
        puts('No username provided')
        exit(1)
      end

      if AdminpgUser.find_by_username(args[:username])
        puts('User already exists')
        exit(1)
      end

      print('Enter a password: ')
      password = STDIN.noecho(&:gets).strip
      puts
      print('Confirm password:')
      confirm_password = STDIN.noecho(&:gets).strip
      puts
      unless password == confirm_password
        puts('\\n Passwords don\'t match')
        exit(1)
      end

      AdminpgUser.create!(username: args[:username], password: password, admin: true)
      puts('User has been created')
    end

    desc 'Update an existing account if it         exists'
    task :update, [:username, :password, :full_name, :first_name, :last_name] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      unless args[:username]
        puts('No username provided')
        exit(1)
      end

      user = AdminpgUser.find_by_username(args[:username])
      if user.nil?
        puts("User '#{args[:username]}' does not exist, it can not be updated")
        exit(1)
      end

      puts("Updating '#{args.to_hash}'")
      user.update!(full_name: args[:full_name]) if args.[](:full_name)
      user.update!(password: args[:password]) if args.[](:password)
      user.update!(first_name: args[:first_name]) if args.[](:first_name)
      user.update!(last_name: args[:last_name]) if args.[](:last_name)

      user1 = user.attributes.select { |key, _value| %w[full_name username password first_name last_name].include?(key) }
      puts("Updated '#{user1.to_json}'")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Show all existent users'
  task :showall, [] => :environment do
    Rake::Task['environment'].invoke
    ActiveRecord::Base.connection

    users = AdminpgUser.all
    users.each do |user|
      user1 = user.attributes.select { |key, _value| %w[id username full_name password].include?(key) }
      puts(user1.to_json)
    end
  rescue ApplicationRedisRecord::RecordNotFound
    puts(e.backtrace)
    exit(1)
  end
end

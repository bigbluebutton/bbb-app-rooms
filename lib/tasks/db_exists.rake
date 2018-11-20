namespace :db do
    desc "Checks to see if the database exists"
    task :exists do
      begin
        Rake::Task['environment'].invoke
        config = ActiveRecord::Base.connection_config
        puts "DB adapter is " + config[:adapter]
        unless config[:adapter] == 'sqlite3'
          ActiveRecord::Base.connection
        end 
      rescue
        puts "Database does not exist..."
        exit 1
      else
        puts "Database already exists..."
        exit 0
      end
    end
  end
namespace :db do
  namespace :servers do
    desc "Add (or update) a new BigBlueButton server (e.g. 'rake db:servers:add[consumer-key,endpoint,secret,internal-endpoint]')"
    task :add, [:key, :endpoint, :secret, :internal] => :environment do |_t, args|
      attrs = {
        endpoint: args[:endpoint],
        secret: args[:secret],
        internal_endpoint: args[:internal]
      }
      puts "Adding or updating the server #{attrs.inspect}"
      config = ConsumerConfig.find_or_create_by(key: args[:key])
      if config.server.present?
        config.server.update(attrs)
      else
        config.create_server(attrs)
      end
    end
  end
end

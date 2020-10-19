namespace :db do
  namespace :brightspace do
    desc "Add (or update) a new configuration for a Brightspace server (e.g. 'rake db:brightspace:add[consumer-key, url, client_id, client_secret]')"
    task :add, [:key, :url, :client_id, :client_secret] => :environment do |_t, args|
      attrs = {
        url: args[:url],
        client_id: args[:client_id],
        client_secret: args[:client_secret],
        scope: "core:*:*" # it only accepts this for now
      }
      puts "Adding or updating the omniauth brightspace #{attrs.inspect}"

      config = ConsumerConfig.find_or_create_by(key: args[:key])
      if config.brightspace_oauth.present?
        config.brightspace_oauth.update(attrs)
      else
        config.create_brightspace_oauth(attrs)
      end
    end
  end
end

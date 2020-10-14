namespace :db do
  namespace :oauth do
    namespace :brightspace do
      desc "Add (or update) a new BrightspaceOauth (e.g. 'rake db:oauth:brightspace:add[consumer-key, url, client_id, client_secret]')"
      task :add, [:key, :url, :client_id, :client_secret] => :environment do |_t, args|
        attrs = {
          url: args[:url],
          client_id: args[:client_id],
          client_secret: args[:client_secret],
          scope: "core:*:*" # it only accepts this for now
        }
        puts "Adding or updating the omniauth brightspace #{attrs.inspect}"
        oauth_brightspace = BrightspaceOauth.create_with(attrs)
          .find_or_create_by(url: attrs[:url])
        server = BigbluebuttonServer.find_by_key args[:key]
        oauth_brightspace.update(attrs)
        server.update(brightspace_oauth: oauth_brightspace)
      end
    end
  end
end

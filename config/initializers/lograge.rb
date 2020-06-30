Rails.application.configure do
  config.lograge.enabled = ENV['LOGRAGE_ENABLED'] == '1'
  # config.lograge.keep_original_rails_log = false
  config.lograge.formatter = Lograge::Formatters::Logstash.new

  config.lograge.custom_options = lambda do |event|
    params = {}
    unless event.payload[:params].nil?
      params = event.payload[:params].reject do |k|
        ['controller', 'action', 'commit', 'utf8'].include? k
      end
      unless params["user"].nil?
        params["user"] = params["user"].reject do |k|
          ['password'].include? k
        end
      end
    end

    hash = { time: event.time }
    hash.merge!({"params" => params}) unless params.blank?
    # hash.merge!({"session" => event.payload[:session]}) unless event.payload[:session].nil?
    hash.merge!({"user" => event.payload[:user]}) unless event.payload[:user].nil?
    hash.merge!({"room" => event.payload[:room]}) unless event.payload[:room].nil?
    hash
  end
end

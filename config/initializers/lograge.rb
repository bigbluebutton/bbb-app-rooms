require 'simple_json_formatter'

Rails.application.configure do
  if ENV['LOGRAGE_ENABLED'] == '1'
    config.lograge.enabled = true
    # config.lograge.keep_original_rails_log = false
    config.lograge.formatter = Lograge::Formatters::Logstash.new

    config.lograge.ignore_actions = ['HealthCheckController#all']

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

      hash = {
        time: event.time,
        exception: event.payload[:exception], # ["ExceptionClass", "the message"]
        exception_object: event.payload[:exception_object] # the exception instance
      }
      hash.merge!({"params" => params}) unless params.blank?
      hash.merge!({"session" => event.payload[:session]}) unless event.payload[:session].nil?
      hash.merge!({"user" => event.payload[:user]}) unless event.payload[:user].nil?
      hash.merge!({"room" => event.payload[:room]}) unless event.payload[:room].nil?
      hash
    end
  end
end

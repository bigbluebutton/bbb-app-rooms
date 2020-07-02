class SimpleJsonFormatter < ActiveSupport::Logger::SimpleFormatter
  def call(severity, _time, _progname, msg)
    log = {
      "@timestamp": Time.now.utc,
      level: severity
    }

    begin
      # so that lograge's logs aren't double quoted
      msg = JSON.parse(msg)
    rescue
    end

    log[:message] = msg
    log.to_json + "\n"
  end
end

# frozen_string_literal: true

require 'syslog/logger'
require_relative '../../lib/custom_logger'

# Initialize stdout logger
stdout_appender = Logging.appenders.stdout(
  layout: Logging.layouts.pattern(
    pattern: '[%d] %-5l %c: %m\n',
    date_pattern: '%Y-%m-%d %H:%M:%S'
  )
)

Logging.logger.root.appenders = stdout_appender

# Initialize remote logger (E.g for Papertrail)
if ENV['RAILS_LOG_REMOTE_NAME'] && ENV['RAILS_LOG_REMOTE_PORT']
  require 'remote_syslog_logger'
  remote_logger = RemoteSyslogLogger.new(
    ENV['RAILS_LOG_REMOTE_NAME'],
    ENV['RAILS_LOG_REMOTE_PORT'].to_i,
    program: ENV['RAILS_LOG_REMOTE_TAG'] || "bbb-lti-broker-#{ENV['RAILS_ENV']}"
  )
  Rails.logger.extend(ActiveSupport::Logger.broadcast(remote_logger))
end

# Set the log level from the environment variable or default to debug
log_level = ENV['LOG_LEVEL']&.downcase || 'debug'
Logging.logger.root.level = log_level

# frozen_string_literal: true

require 'logging'
require 'active_support/tagged_logging'

class CustomLogger < ActiveSupport::Logger
  def initialize(_logger_name)
    # Define the log file path based on the Rails environment
    log_file_path = Rails.root.join('log', "#{Rails.env}.log")

    # Initialize the logger to write to the environment-specific log file
    super(log_file_path)

    self.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity} #{progname}: #{msg}\n"
    end
  end
end

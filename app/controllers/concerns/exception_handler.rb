# frozen_string_literal: true

module ExceptionHandler
  include ActiveSupport::Concern
  class CustomError < StandardError
    attr_reader :error
    def initialize(error = :unknown)
      @error = error
    end
  end
end

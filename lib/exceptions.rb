# frozen_string_literal: true

module Exceptions
  class CustomError < StandardError
    attr_reader :error
    def initialize(error = :unknown)
      @error = error
    end
  end
end

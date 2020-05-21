# frozen_string_literal: true

module BbbLtiBroker
  module Helpers
    def string_to_hash(str)
      Hash[
        str.split(',').map do |pair|
          k, v = pair.split(':', 2)
          [k, v]
        end
      ]
    end

    def secure_url(url)
      uri = URI.parse(url)
      uri.scheme = 'https'
      uri.to_s
    end
  end
end

module LtiToolProvider
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
      uri.scheme = "https"
      uri.to_s
    end

    def lti_icon(icon)
      begin
        uri = URI.parse(url)
        uri.to_s
      rescue
        view_context.image_url(icon)
      end
    end
  end
end

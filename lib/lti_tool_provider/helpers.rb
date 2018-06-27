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

    def tokenize(str, secret, salt)
      crypt = crypter(secret, salt)
      crypt.encrypt_and_sign(str.ljust(128, ' '))
    end

    def untokenize(str, secret, salt)
      crypt = crypter(secret, salt)
      crypt.decrypt_and_verify(str).strip
    end

    def crypter(secret, salt)
      key = ActiveSupport::KeyGenerator.new(secret).generate_key(salt, 32)
      ActiveSupport::MessageEncryptor.new(key, {cipher: 'aes-256-cbc', digest: 'SHA1', serializer: Marshal})
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

# frozen_string_literal: true

#  BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
#  Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
#  This program is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free Software
#  Foundation; either version 3.0 of the License, or (at your option) any later
#  version.
#
#  BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#  PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License along
#  with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
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
    rescue StandardError
      nil
    end

    def untokenize(str, secret, salt)
      crypt = crypter(secret, salt)
      crypt.decrypt_and_verify(str).strip
    rescue StandardError
      nil
    end

    def crypter(secret, salt)
      key = ActiveSupport::KeyGenerator.new(secret).generate_key(salt, 32)
      ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-cbc', digest: 'SHA1', serializer: Marshal)
    end
  end
end

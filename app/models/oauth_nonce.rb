# frozen_string_literal: true

class OAuthNonce < ApplicationRecord
    validates :nonce, :timestamp, presence: true
    self.table_name = "oauth_nonces"
end

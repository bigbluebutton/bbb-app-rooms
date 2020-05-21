# frozen_string_literal: true

class OAuthConsumer < ApplicationRecord
    validates :key, :secret, presence: true
    self.table_name = "oauth_consumers"
end

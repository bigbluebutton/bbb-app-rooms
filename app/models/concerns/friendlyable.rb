# frozen_string_literal: true

module Friendlyable
  extend ActiveSupport::Concern

  ALPHANUM = [*'a'..'z', *'A'..'Z', *'0'..'9'].freeze

  included do
    extend ::FriendlyId
    before_create :set_hash_id
    friendly_id :hash_id
  end

  def set_hash_id
    hash_id = nil
    id_length = 5
    loop do
      hash_id = SecureRandom.urlsafe_base64(id_length)
      hash_id = replace_prohibited_chars(hash_id)
      break unless self.class.name.constantize.exists?(hash_id: hash_id)
    end
    self.hash_id = hash_id
  end

  private

  # Replace '-' and '_' from str with random alphanumeric chars
  def replace_prohibited_chars(str)
    str.gsub(/-|_/) { |_| ALPHANUM.sample }
  end
end


module OauthConfig

    def nonce_used?
        OAuthNonce.where(:nonce => nonce, :timestamp => timestamp).any?
    end

    def use_nonce!
        OAuthNonce.create!(:nonce => nonce, :timestamp => timestamp)
    end

    def timestamp_valid_period
        30
    end

    def allowed_signature_methods
        %w(HMAC-SHA1)
    end

    def consumer_secret
        OAuthConsumer.where(:key => consumer_key).first.try(:secret)
    end

    def body_hash_required?
        false
    end

end
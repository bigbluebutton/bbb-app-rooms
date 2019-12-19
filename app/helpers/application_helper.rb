module ApplicationHelper
  def omniauth_authorize_path(provider)
    path = omniauth_callback_path(provider)
    path.slice(0..(path.index('/callback') - 1))
  end

  def omniauth_authorize_url(provider)
    url = omniauth_callback_url(provider)
    url.slice(0..(url.index('/callback') - 1))
  end

  def omniauth_bbbltibroker_url(url)
    url.slice(0..(url.index('/api') - 1))
  end

  def omniauth_client_token(lti_broker_url)
    response = RestClient.post("#{lti_broker_url}/oauth/token", oauth_options)
    JSON.parse(response)["access_token"]
  end

  def oauth_options
    {
      grant_type: 'client_credentials',
      client_id: Rails.configuration.omniauth_bbbltibroker_key,
      client_secret: Rails.configuration.omniauth_bbbltibroker_secret
    }
  end

  def omniauth_provider?(code)
    provider = code.to_s
    OmniAuth::strategies.each do |strategy|
      return true if provider.downcase == strategy.to_s.demodulize.downcase
    end
    false
  end
end

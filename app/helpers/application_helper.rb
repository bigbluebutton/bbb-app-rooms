module ApplicationHelper
  def omniauth_client_token(lti_broker_url)
    puts 'helper omniauth_client_token...'
    response = RestClient.post("#{lti_broker_url}/oauth/token", oauth_options)
    JSON.parse(response)["access_token"]
  end

  def oauth_options
    puts 'helper oauth_options...'
    {
      grant_type: 'client_credentials',
      client_id: Rails.configuration.omniauth_bbbltibroker_key,
      client_secret: Rails.configuration.omniauth_bbbltibroker_secret
    }
  end

  def omniauth_provider?(code)
    puts 'helper omniauth_provider...'
    provider = code.to_s
    OmniAuth::strategies.each do |strategy|
      puts strategy.to_s.demodulize.downcase
      return true if provider.downcase == strategy.to_s.demodulize.downcase
    end
    false
  end
end

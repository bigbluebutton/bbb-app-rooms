module ApplicationHelper

  def omniauth_bbbltibroker_url(path = nil)
    url = Rails.configuration.omniauth_site
    url += Rails.configuration.omniauth_root if Rails.configuration.omniauth_root.present?
    url += path unless path.nil?
    url
  end

  def omniauth_client_token(lti_broker_url)
    oauth_options = {
        grant_type: 'client_credentials',
        client_id: Rails.configuration.omniauth_key,
        client_secret: Rails.configuration.omniauth_secret
      }
    response = RestClient.post("#{lti_broker_url}/oauth/token", oauth_options)
    JSON.parse(response)["access_token"]
  end

  def omniauth_provider?(code)
    provider = code.to_s
    OmniAuth::strategies.each do |strategy|
      return true if provider.downcase == strategy.to_s.demodulize.downcase
    end
    false
  end
end

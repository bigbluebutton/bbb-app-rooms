# frozen_string_literal: true

module DeepLinkService
  include ActiveSupport::Concern

  def deep_link_resource(url, custom_params, title)
    resource = {
      'type' => 'ltiResourceLink',
      'title' => title,
      'url' => url,
      'presentation' => {
        'documentTarget' => 'window'
      },
      'custom' => custom_params
    }
  end

  def deep_link_jwt_response(registration, jwt_header, jwt_body, resources)
    message = {
      'iss' => registration['client_id'],
      'aud' => [registration['issuer']],
      'exp' => Time.now.to_i + 600,
      'iat' => Time.now.to_i,
      'nonce' => 'nonce' + SecureRandom.hex,
      'https://purl.imsglobal.org/spec/lti/claim/deployment_id' => jwt_body['https://purl.imsglobal.org/spec/lti/claim/deployment_id'],
      'https://purl.imsglobal.org/spec/lti/claim/message_type' => 'LtiDeepLinkingResponse',
      'https://purl.imsglobal.org/spec/lti/claim/version' => '1.3.0',
      'https://purl.imsglobal.org/spec/lti-dl/claim/content_items' => resources,
      'https://purl.imsglobal.org/spec/lti-dl/claim/data' => jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['data']
    }

    message.each do |key, value|
      message[key] = '' if value.nil?
    end

    priv = File.read(registration['tool_private_key'])
    priv_key = OpenSSL::PKey::RSA.new(priv)

    JWT.encode message, priv_key, 'RS256', kid: jwt_header['kid']
  end
end

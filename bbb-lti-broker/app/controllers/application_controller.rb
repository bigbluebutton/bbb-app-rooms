require "uri"
require "net/http"
require "ims/lti"
require "securerandom"
require "faraday"
require 'oauthenticator'
require 'oauth'
require 'addressable/uri'

class ApplicationController < ActionController::Base
  include RoomsValidator
  include OauthConfig

  before_action :verify_auth

  protect_from_forgery with: :exception
  # CSRF stuff ^

  # verified oauth, etc
  # launch into bigbluebutton
  def launch
    puts "ApplicationController: launch"

    # Make launch request to BBB-LTI
    method = 'POST'
    uri = 'https://bbb.peter.blindside-dev.com'
    consumer_key = 'bbb'
    consumer_secret = '9834854ab45c356a0aff30122134e7b8'

    signing_options = {
      :signature_method => 'HMAC-SHA1',
      :consumer_key => 'bbb',
      :consumer_secret => '9834854ab45c356a0aff30122134e7b8'
    }

    connection = Faraday.new(uri) do |faraday|
      faraday.request :url_encoded
      faraday.request :oauthenticator_signer, signing_options
      faraday.adapter Faraday.default_adapter
    end

    oauth_signable_request = OAuthenticator::SignableRequest.new(
      :request_method => 'POST',
      :media_type => nil,
      :body => nil,
      :uri => uri + '/lti/tool',
      :signature_method => 'HMAC-SHA1',
      :consumer_key => consumer_key,
      :consumer_secret => consumer_secret
    )

    oauth_signature = oauth_signable_request.signature
    oauth_params = oauth_signable_request.signed_protocol_params

    puts oauth_signature
    puts oauth_params.to_s


    lti_params = {
      'lti_version' => 'LTI-1p0',
      'lti_message_type' => params['lti_message_type'],
      'resource_link_id' => params['resource_link_id'],
      'resource_link_title' => params['resource_link_title'],
      'launch_presentation_return_url' => params['launch_presentation_return_url'],
      'user_id' => params['user_id'],
      'lis_person_name_given' => params['lis_person_name_given'],
      'lis_person_name_family' => params['lis_person_lis_person_name_family'],
      'tool_consumer_instance_guid' => params['tool_consumer_instance_guid'],
      'oauth_signature_method' => 'HMAC-SHA1',
      'oauth_consumer_key' => 'bbb',
      'oauth_nonce' => oauth_params['oauth_nonce'],
      'oauth_version' => '1.0',
      'oauth_timestamp' => oauth_params['oauth_timestamp'],
      'request_method' => 'POST',
      'controller' => params['app'],
      'format' => 'null'
    }


    res = connection.post('/lti/tool') do |req|
      puts req.headers
      req.params = lti_params
    end

    puts res.body
    puts "Status: " + res.status.to_s
    puts "Headers: " + res.headers.to_s
    # Redirect to BBB html client
    redirect_to res.headers['location']
  end

  def verify_auth
    lti_version = params['lti_version']
    if(lti_version == 'LTI-1p0')
      # Verify OAuth 1.0 signature for LTI 1.0 request
      # According to OAuth spec RFC 5849 https://tools.ietf.org/html/rfc5849
      puts "Verify OAuth 1.0 signature for LTI 1.0 request"

      key = "key"
      secret = "secret"
      base_string = "POST&"

      # Concatenate base string URI
      base_uri = Addressable::URI.escape('http://broker.peter.blindside-dev.com/lti/tool/messages/blti') + "&"
      base_string += base_uri

      base_params_hash = params.to_unsafe_h.except!('oauth_signature').except!('app')

      # Encode keys and values
      encoded_base_params_hash = {}
      base_params_hash.each do | key, val |
        enc_key = Addressable::URI.escape(key)
        enc_val = Addressable::URI.escape(val)
        encoded_base_params_hash[enc_key] = enc_val
      end

      # Sort by key
      encoded_base_params_hash.keys.sort

      param_strings = []
      encoded_base_params_hash.each do | key, val |
        param_strings.push("#{key}=#{val}")
      end

      base_param_string = param_strings.join("&")

      base_string += base_param_string

      calculated_signature = Addressable::URI.escape(Base64.encode64("#{OpenSSL::HMAC.digest('sha1', secret, base_string)}").chomp)

      if( calculated_signature != params['oauth_signature'] )
        puts "Calculated: " + calculated_signature
        puts "Given: " + params['oauth_signature']
        puts "OAuth Signature not OK"
        render :launch_error
      end

    elsif(lti_version == '1.3.0')
      # Verify OAuth 2.0 for LTI 1.3 request
      puts "Verify OAuth 2.0 for LTI 1.3 request"
      
    else
      puts "LTI Version not detected"
    end
  end
end

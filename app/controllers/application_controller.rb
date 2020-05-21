# frozen_string_literal: true

require "uri"
require "net/http"
require "ims/lti"
require "securerandom"
require "faraday"
require 'oauthenticator'
require 'oauth'
require 'addressable/uri'
require 'oauth/request_proxy/action_controller_request'

class ApplicationController < ActionController::Base
  include RoomsValidator

  before_action :verify_auth

  protect_from_forgery with: :exception
  # CSRF stuff ^

  # verified oauth, etc
  # launch into bigbluebutton
  def launch
    puts "ApplicationController: launch"

    # Make launch request to BBB-LTI
    app = lti_app(params[:app])
    puts app.to_s
    @tool_uri = app['redirect_uri']
    @method = 'POST'
    @consumer_key = app['uid']
    @consumer_secret = app['secret']

    parameters = params.to_unsafe_h
    parameters.delete('action')
    parameters.delete('app')
    parameters.delete('oauth_signature')
    parameters['request_method'] = 'POST'
    parameters['format'] = 'null'
    parameters['oauth_consumer_key'] = @consumer_key

    request = OAuth::RequestProxy::MockRequest.new(
      'method' => @method,
      'uri' => @tool_uri,
      'parameters' => parameters
    )

    signature = OAuth::Signature::HMAC::SHA1.new(request, :consumer_secret => @consumer_secret).signature

    puts "BBB Sig: " + signature.to_s
    parameters['oauth_signature'] = signature

    uri = Addressable::URI.parse(@tool_uri)
    uri.query_values = parameters
    puts "BBB uri: " + uri

    req = Net::HTTP::Post.new(uri)

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    puts "Response" + res.inspect

    # Redirect to tool server
    redirect_to res['location']
  end

  def verify_auth
    lti_version = params['lti_version']
    if(lti_version == 'LTI-1p0')
      # Verify OAuth 1.0 signature for LTI 1.0 request
      # According to OAuth spec RFC 5849 https://tools.ietf.org/html/rfc5849
      puts "Verify OAuth 1.0 signature for LTI 1.0 request"

      broker_key = ENV['CONSUMER_KEY']
      broker_secret = ENV['CONSUMER_SECRET']
      puts "secret: " + broker_secret
      app = lti_app(params[:app])
      tool_name = app['name']

      parameters = params.to_unsafe_h
      parameters.delete('action')
      parameters.delete('app')
      parameters.delete('controller')

      request = OAuth::RequestProxy::MockRequest.new(
        'method' => 'POST',
        'uri' => "http://broker.peter.blindside-dev.com/lti/#{tool_name}/messages/blti",
        'parameters' => parameters
      )

      if OAuth::Signature::HMAC::SHA1.new(request, :consumer_secret => broker_secret).verify
        puts "OAuth OK"
      else
        puts "OAuth FAIL"
        render :launch_error
      end
    end
  end
end

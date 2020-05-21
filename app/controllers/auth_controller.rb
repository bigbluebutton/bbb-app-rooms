# frozen_string_literal: true

require 'ims/lti'
require 'securerandom'

class AuthController < ApplicationController
  include ExceptionHandler
  include PlatformValidator

  skip_before_action :verify_authenticity_token
  before_action :validate_oidc_login

  # first touch point for lti 1.3
  # ensures platform is registered
  def login
    puts "AuthController: login"

    state = 'state' + SecureRandom.hex

    cookies[state] = {
      value: state,
      expires: 1.year.from_now
    }

    nonce = 'nonce' + SecureRandom.hex
    Rails.cache.write('lti1p3_' + nonce, nonce: nonce)

    auth_params = {
      scope: 'openid',
      response_type: 'id_token',
      response_mode: 'form_post',
      prompt: 'none',
      client_id: @registration['client_id'],
      redirect_uri: params[:target_link_uri],
      state: state,
      nonce: nonce,
      login_hint: params[:login_hint]
    }

    if params.key?(:lti_message_hint)
      auth_params[:lti_message_hint] = params[:lti_message_hint]
    end

    aparams = URI.encode_www_form(auth_params)
    redirect_to @registration['auth_login_url'] + '?' + aparams
  end

  private

  def validate_oidc_login
    raise CustomError, :could_not_find_issuer unless params.key?('iss')
    raise CustomError, :could_not_find_login_hint unless params.key?('login_hint')

    options = {}
    options['client_id'] = params[:client_id] if params.key?('client_id')

    raise CustomError, :not_registered unless lti_registration_exists?(params[:iss], options)

    @registration = lti_registration_params(params[:iss], options)
  end
end

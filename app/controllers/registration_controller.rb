# frozen_string_literal: true

require 'json'
require 'pathname'

class RegistrationController < ApplicationController
  skip_before_action :verify_authenticity_token
  include PlatformValidator
  include RoomsValidator
  include TemporaryStore

  def list
    @registrations = RailsLti2Provider::Tool.where(lti_version: '1.3.0').pluck(:tool_settings)
    @registrations.map! do |reg|
      JSON.parse reg
    end
  end

  # only available if developer mode is on
  # production - use rails task
  def new
    @app = ENV['DEFAULT_LTI_TOOL'] || 'default'
    @apps = lti_apps
    set_temp_keys
    set_starter_info
  end

  def edit
    redirect_to registration_list_path unless params.key?('reg_id') && params.key?('client_id')
    options = {}
    options['client_id'] = params[:client_id] if params.key?('client_id')
    redirect_to registration_list_path unless lti_registration_exists?(params[:reg_id], options)

    @registration = lti_registration_params(params[:reg_id], options)
  end

  def submit
    return if params[:iss] == ''

    reg = {
      issuer: params[:iss],
      client_id: params[:client_id],
      key_set_url: params[:key_set_url],
      auth_token_url: params[:auth_token_url],
      auth_login_url: params[:auth_login_url]
    }

    if params.key?('private_key_path') && params.key?('public_key_path')
      key_dir = Digest::MD5.hexdigest params[:iss] + params[:client_id]
      Dir.mkdir('.ssh/') unless Dir.exists?('.ssh/')
      Dir.mkdir('.ssh/' + key_dir) unless Dir.exists?('.ssh/' + key_dir)

      priv_key = read_temp_file(params[:private_key_path])
      pub_key = read_temp_file(params[:public_key_path])

      File.open(File.join(Rails.root, '.ssh', key_dir, 'priv_key'), 'w') do |f|
        f.puts priv_key
      end

      Rails.root.join('path/to')
      File.open(File.join(Rails.root, '.ssh', key_dir, 'pub_key'), 'w') do |f|
        f.puts pub_key
      end

      reg[:tool_private_key] = "#{Rails.root}/.ssh/#{key_dir}/priv_key"
    end

    options = {}
    options['client_id'] = params[:client_id]

    if params.key?('reg_id')
      if lti_registration_exists?(params[:reg_id], options)
        registration = lti_registration(params[:reg_id], options)
        reg[:tool_private_key] = lti_registration_params(params[:reg_id], options)['tool_private_key']
        registration.update(tool_settings: reg.to_json, shared_secret: params[:client_id])
        registration.save
      end
    # elsif ! lti_registration_exists?(params[:iss])
    else
      RailsLti2Provider::Tool.create!(
        uuid: params[:iss],
        shared_secret: params[:client_id],
        tool_settings: reg.to_json,
        lti_version: '1.3.0'
      )
    end

    redirect_to registration_list_path
  end

  def delete
    options = {}
    options['client_id'] = params[:client_id] if params.key?('client_id')
    if lti_registration_exists?(params[:reg_id], options)
      reg = lti_registration(params[:reg_id], options)
      if lti_registration_params(params[:reg_id], options)['tool_private_key'].present?
        key_dir = Pathname.new(lti_registration_params(params[:reg_id])['tool_private_key']).parent.to_s
        FileUtils.remove_dir(key_dir, true) if Dir.exist? key_dir
      end
      reg.delete
    end
    redirect_to registration_list_path
  end

  private

  def set_temp_keys
    private_key = OpenSSL::PKey::RSA.generate 4096
    @jwk = JWT::JWK.new(private_key).export
    @jwk['alg'] = 'RS256' unless @jwk.key? 'alg'
    @jwk['use'] = 'sig' unless @jwk.key? 'use'
    @jwk = @jwk.to_json

    @public_key = private_key.public_key

    # keep temp files in scope so they are not deleted
    @public_key_file = store_temp_file('bbb-lti-rsa-pub-', @public_key.to_s)
    @private_key_file = store_temp_file('bbb-lti-rsa-pri-', private_key.to_s)

    # keep paths in cache for json configuration
    @temp_key_token = SecureRandom.hex
    Rails.cache.write(@temp_key_token, public_key_path: @public_key_file.path, private_key_path: @private_key_file.path, timestamp: Time.now.to_i)
  end

  def set_starter_info
    basic_launch_url = openid_launch_url(app: @app)
    deep_link_url = deep_link_request_launch_url(app: @app)
    @redirect_uri = basic_launch_url + "\n" + deep_link_url
  end
end

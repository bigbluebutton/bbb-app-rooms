# required for LTI
require 'ims/lti'
# Used to validate oauth signatures
require 'oauth/request_proxy/action_controller_request'

require 'helpers/message_helper'

class MessageController < ApplicationController
  include RailsLti2Provider::ControllerHelpers
  helper MessageHelper

  # skip rail default verify auth token - we use our own strategies
  skip_before_action :verify_authenticity_token
  # verify that the application belongs to us before doing anything with it
  before_action :lti_authorized_application
  # validates message with oauth in rails lti2 provider gem
  before_action :lti_authentication, except: %i[signed_content_item_request]

  # fails lti_authentication in rails lti2 provider gem
  rescue_from RailsLti2Provider::LtiLaunch::Unauthorized do |ex|
    @error = 'Authentication failed with: ' + case ex.error
                                              when :invalid_key
                                                'The LTI key used is invalid'
                                              when :invalid_signature
                                                'The OAuth Signature was Invalid'
                                              when :invalid_nonce
                                                'The nonce has already been used'
                                              when :request_too_old
                                                'The request is too old'
                                              else
                                                'Unknown Error'
                                              end
    @message = IMS::LTI::Models::Messages::Message.generate(request.request_parameters)
    @header = SimpleOAuth::Header.new(:post, request.url, @message.post_params, consumer_key: @message.oauth_consumer_key, consumer_secret: helpers.lti_secret(@message.oauth_consumer_key), callback: 'about:blank')
    if request.request_parameters.key?('launch_presentation_return_url')
      launch_presentation_return_url = request.request_parameters['launch_presentation_return_url'] + '&lti_errormsg=' + @error
      redirect_to launch_presentation_return_url
    else
      render :basic_lti_launch_request, status: 200
    end
  end
  
  # first touch point from tool consumer (moodle, canvas, etc)
  def basic_lti_launch_request
    process_message
    unless params[:app] == 'default'
      # Redirect to external application if configured
      Rails.cache.write(params[:oauth_nonce], {message: @message, oauth: {consumer_key: params[:oauth_consumer_key], timestamp: params[:oauth_timestamp]}})
      session[:user_id] = @current_user.id
      tc_instance_guid = helpers.tool_consumer_instance_guid(request.referrer, params)
      redirect_to lti_apps_path(params[:app], sso: api_v1_sso_launch_url(params[:oauth_nonce]), handler: helpers.resource_handler(tc_instance_guid, params))
    end
  end

  # for /lti/:app/xml_builder enable placement for message type: content_item_selection_request
  def content_item_selection
    process_message
  end

  private
    # called by all requests to process the message first
    def process_message
      # TODO: should we create the lti_launch with all of the oauth params as well?
      @message = (@lti_launch && @lti_launch.message) || IMS::LTI::Models::Messages::Message.generate(request.request_parameters)
      tc_instance_guid = helpers.tool_consumer_instance_guid(request.referrer, params)
      @header = SimpleOAuth::Header.new(:post, request.url, @message.post_params, consumer_key: @message.oauth_consumer_key, consumer_secret: helpers.lti_secret(@message.oauth_consumer_key), callback: 'about:blank')
      @current_user = User.find_by(context: tc_instance_guid, uid: params['user_id']) || User.create(helpers.user_params(tc_instance_guid, params))
    end

    # called by all requests to verify application existence first
    def lti_authorized_application
      # app is missing from tool registration - get app from custom_app if that is the case
      params[:app] = params[:custom_app] unless params.key?(:app) || ! params.key?(:custom_app)
      raise CustomError.new(:missing_app) unless params.key?(:app)
      raise CustomError.new(:not_found) unless params[:app] == 'default' || helpers.authorized_tools.key?(params[:app])
    end
end
  
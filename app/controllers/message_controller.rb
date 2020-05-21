# frozen_string_literal: true

# required for LTI
require 'ims/lti'
# Used to validate oauth signatures
require 'oauth/request_proxy/action_controller_request'

class MessageController < ApplicationController
  include RailsLti2Provider::ControllerHelpers
  include ExceptionHandler
  include OpenIdAuthenticator
  include RoomsValidator
  include PlatformValidator
  include DeepLinkService

  # skip rail default verify auth token - we use our own strategies
  skip_before_action :verify_authenticity_token
  # verify that the application belongs to us before doing anything with it
  before_action :lti_authorized_application

  # validates message with oauth in rails lti2 provider gem
  before_action :lti_authentication, except: %i[signed_content_item_request openid_launch_request deep_link]

  before_action :verify_blti_launch, only: %i[openid_launch_request deep_link]

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
    @header = SimpleOAuth::Header.new(:post, request.url, @message.post_params, consumer_key: @message.oauth_consumer_key, consumer_secret: lti_secret(@message.oauth_consumer_key), callback: 'about:blank')
    if request.request_parameters.key?('launch_presentation_return_url')
      launch_presentation_return_url = request.request_parameters['launch_presentation_return_url'] + '&lti_errormsg=' + @error
      redirect_to(launch_presentation_return_url)
    else
      render(:basic_lti_launch_request, status: :ok)
    end
  end

  def openid_launch_request
    return if params[:app] == 'default'

    nonce = @jwt_body['nonce']
    # Redirect to external application if configured
    Rails.cache.write(nonce, message: @message, oauth: { timestamp: @jwt_body['exp'] }, lti_launch_nonce: @lti_launch.nonce)
    session[:user_id] = @current_user.id
    redirect_to(lti_apps_path(params.to_unsafe_h))
  end

  # first touch point from tool consumer (moodle, canvas, etc)
  def basic_lti_launch_request
    process_message
    return if params[:app] == 'default'

    # Redirect to external application if configured
    Rails.cache.write(params[:oauth_nonce], message: @message, oauth: { consumer_key: params[:oauth_consumer_key], timestamp: params[:oauth_timestamp] })
    session[:user_id] = @current_user.id
    redirect_to(lti_apps_path(params.to_unsafe_h))
  end

  # for /lti/:app/xml_builder enable placement for message type: content_item_selection_request
  # shows select content on tool configuration page in platform
  def content_item_selection
    process_message
    @launch_url = blti_launch_url
    @update_url = content_item_request_launch_url
    @oauth_consumer_key = params[:oauth_consumer_key]
  end

  # submit content item selection
  def signed_content_item_request
    launch_url = params.delete('return_url')
    tool = RailsLti2Provider::Tool.where(uuid: request.request_parameters[:oauth_consumer_key]).last
    message = IMS::LTI::Models::Messages::Message.generate(request.request_parameters)
    message.launch_url = launch_url
    @launch_params = { launch_url: message.launch_url, signed_params: message.signed_post_params(tool.shared_secret) }
    render('message/signed_content_item_form')
  end

  def deep_link
    resource = deep_link_resource(openid_launch_url, { 'What\'s black and white and red all over?': 'A sunburnt panda' }, 'My room')
    @deep_link_jwt_message = deep_link_jwt_response(lti_registration_params(@jwt_body['iss']), @jwt_header, @jwt_body, [resource])
    @deep_link_return_url = @jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['deep_link_return_url']
  end

  private

  # called by all requests to process the message first
  def process_message
    # TODO: should we create the lti_launch with all of the oauth params as well?
    @message = (@lti_launch&.message) || IMS::LTI::Models::Messages::Message.generate(request.request_parameters)

    tc_instance_guid = tool_consumer_instance_guid(request.referrer, params)
    @header = SimpleOAuth::Header.new(:post, request.url, @message.post_params, consumer_key: @message.oauth_consumer_key, consumer_secret: lti_secret(@message.oauth_consumer_key), callback: 'about:blank')
    @current_user = User.find_by(context: tc_instance_guid, uid: params['user_id']) || User.create(user_params(tc_instance_guid, params))
  end

  # verify lti 1.3 launch
  def verify_blti_launch
    jwt = verify_openid_launch
    @jwt_body = jwt[:body]
    logger.info("JWT Body: " + @jwt_body.to_s)
    @jwt_header = jwt[:header]
    check_launch
    @message = IMS::LTI::Models::Messages::Message.generate(params)
    tc_instance_guid = tool_consumer_instance_guid(request.referrer, params)
    @header = SimpleOAuth::Header.new(:post, request.url, @message.post_params, callback: 'about:blank')
    @current_user = User.find_by(context: tc_instance_guid, uid: params[:user_id]) || User.create(user_params(tc_instance_guid, params))
  end

  def check_launch
    tool = lti_registration(@jwt_body['iss'])
    tool.lti_launches.where('created_at > ?', 1.day.ago).delete_all
    @lti_launch = tool.lti_launches.create(nonce: @jwt_body['nonce'], message: @jwt_body.merge(@jwt_header))
  end
end

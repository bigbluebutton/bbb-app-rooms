class MessageController < ApplicationController
  include ApplicationHelper
  include RailsLti2Provider::ControllerHelpers

  skip_before_action :verify_authenticity_token
  before_filter :lti_authorized_application
  before_filter :lti_authentication, except: %i[youtube signed_content_item_request]

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
      redirect_to launch_presentation_return_url
    else
      render :basic_lti_launch_request, status: 200
    end
  end

  def basic_lti_launch_request
    process_message
    log_hash params
    # Redirect to external application if configured
    Rails.cache.write params[:oauth_nonce], {message: @message, oauth: {consumer_key: params[:oauth_consumer_key], timestamp: params[:oauth_timestamp]}}
    token = tokenize(api_v1_sso_launches_url(params[:oauth_nonce]), authorized_tools[params[:app]]["secret"], params[:app])
    redirect_to lti_apps_url(params[:app], token: token, handler: resource_handler) unless params[:app] == 'default'
  end

  def content_item_selection
    process_message
  end

  def signed_content_item_request
    key = 'key' # this should ideally be sent up via api call
    launch_url = params.delete('return_url')
    tool = RailsLti2Provider::Tool.where(uuid: 'key').last
    message = IMS::LTI::Models::Messages::Message.generate(request.request_parameters.merge(oauth_consumer_key: key))
    message.launch_url = launch_url
    @launch_params = { launch_url: message.launch_url, signed_params: message.signed_post_params(tool.shared_secret) }
    render 'message/signed_content_item_form'
  end

  def youtube
    redirect_to params[:youtube_url]
  end

  private
    def process_message
      @secret = "&#{RailsLti2Provider::Tool.find(@lti_launch.tool_id).shared_secret}"
      # TODO: should we create the lti_launch with all of the oauth params as well?
      @message = (@lti_launch && @lti_launch.message) || IMS::LTI::Models::Messages::Message.generate(request.request_parameters)
      @header = SimpleOAuth::Header.new(:post, request.url, @message.post_params, consumer_key: @message.oauth_consumer_key, consumer_secret: lti_secret(@message.oauth_consumer_key), callback: 'about:blank')
    end

    def resource_handler
      Digest::SHA1.hexdigest(params[:app] + params["tool_consumer_instance_guid"] + params["resource_link_id"])
    end
end

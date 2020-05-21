# frozen_string_literal: true

class Api::V1::SsoController < Api::V1::BaseController
  # before_action :doorkeeper_authorize!

  def validate_launch
    response = { token: params[:token], valid: token_valid? }
    response[:message] = @message if @message
    response[:error] = @error if @error
    response[:grades] = @grades if @grades
    render json: response.to_json
  end

  private

  def token_valid?
    launch = Rails.cache.read(params[:token])
    unless launch
      @error = { error: { key: 'token_invalid', message: 'The token does not exist' } }
      return false
    end
    if launch[:oauth][:timestamp].to_i < 30.minutes.ago.to_i
      @error = { key: 'token_expired', message: 'The token has expired' }
      return false
    end
    @message = launch[:message]

    if supported_grade_versions.include? @message.lti_version
      @lti_launch_nonce = launch[:lti_launch_nonce]
      @grades = {
        send_grades_url: grades_list_url(grades_token)
      }
    end

    true
  end

  def supported_grade_versions
    ['1.3.0']
  end

  def grades_token
    token = SecureRandom.hex
    puts '--------------------- set launch nonce --------------------------'
    puts @lti_launch_nonce
    puts '-----------------------------------------------------------------'
    Rails.cache.write(token, lti_launch_nonce: @lti_launch_nonce, timestamp: Time.now.to_i)
    token
  end
end

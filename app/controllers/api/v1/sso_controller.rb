class Api::V1::SsoController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def validate_launch
    response = {token: params[:token], valid: token_valid?}
    response[:message] = @message if @message
    response[:error] = @error if @error
    render json: response.to_json
  end

  private

    def token_valid?
      launch = Rails.cache.read(params[:token])
      if !launch
        @error = {error: {key: 'token_invalid', message: 'The token does not exist'} }
        return false
      end
      if launch[:oauth][:timestamp].to_i < 30.minutes.ago.to_i
        @error = {key: 'token_expired', message: 'The token has expired'}
        return false
      end
      @message = launch[:message]
      true
    end

end

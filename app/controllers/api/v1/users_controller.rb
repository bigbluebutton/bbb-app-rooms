class Api::V1::UsersController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def show
    if params[:id]
      user = find_user
    else
      user = current_user
    end
    render json: user.as_json(except: :password_digest)
  end

end

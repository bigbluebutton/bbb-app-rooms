class Api::V1::BaseController < ApplicationController

  private

    def current_user
      return nil unless doorkeeper_token
      @current_user ||= User.find(doorkeeper_token.resource_owner_id)
    end

    def find_user
      return nil unless doorkeeper_token
      User.find(params[:id])
    end

end

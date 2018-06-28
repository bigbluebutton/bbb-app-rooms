class AppsController < ApplicationController
  include ApplicationHelper

  def index
    redirect_to app_url
  end

  private

    def app_url
      root = authorized_tools[params[:app]]["root"]
      "#{root ? "/#{root}" : ''}/#{params[:app]}/launch?#{params.except(:app).to_query}"
    end

end

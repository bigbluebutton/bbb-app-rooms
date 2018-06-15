class AppsController < ApplicationController
  include AppsHelper

  def index
    redirect_to app_url
  end

  private

    def app_url
      root = lti_apps[params[:app]]
      "#{root ? "/#{root}" : ''}/#{params[:app]}/launch?#{params.except(:app).to_query}"
    end

end

class AppsController < ApplicationController
  include ApplicationHelper

  def index
    redirect_to app_url
  end

  private

  def app_url
    app = lti_app(params[:app])
    baseurl = URI.join(app['redirect_uri'], '/').to_s
    "#{baseurl}launch?#{params.except(:app, :controller, :action).to_query}"
  end

end

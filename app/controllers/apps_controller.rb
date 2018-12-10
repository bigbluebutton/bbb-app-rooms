class AppsController < ApplicationController
  include ApplicationHelper

  def index
    redirect_to app_url
  end

  private

  def app_url
    app = lti_app(params[:app])
    uri = URI.parse(app['redirect_uri'])
    root = uri.path.sub("#{app['name']}/auth/bbbltibroker/callback", '')
    root = root.gsub('/', '')
    "#{root ? '/' + root : ''}/#{params[:app]}/launch?#{params.except(:app, :controller, :action).to_query}"
  end

end

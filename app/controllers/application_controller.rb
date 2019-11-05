require 'helpers/application_helper'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # CSRF stuff ^

  helper ApplicationHelper

  # verified oauth, etc
  # launch into bigbluebutton
  def launch
    app = lti_app(params[:app])
    uri = URI.parse(app['redirect_uri'])
    site = "#{uri.scheme}://#{uri.host}#{uri.port ? ':' + uri.port.to_s : ''}"
    path = uri.path.split('/')
    root = ("" == path[0].chomp(" ") ? path[1] : path[0]).gsub('/', '')
    redirect_to "#{site}#{root ? '/' + root : ''}/#{params[:app]}/launch?#{params.except(:app, :controller, :action).permit(:sso, :handler).to_query}"
  end

  # Get doorkeeper entry for application name (unique)
  def lti_app(name)
    app = Doorkeeper::Application.where(name: name).first
    app.attributes.select { |key, value| ['name', 'uid', 'secret', 'redirect_uri'].include?(key) }
  end

end

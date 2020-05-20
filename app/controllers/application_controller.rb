class ApplicationController < ActionController::Base
  include RoomsValidator

  protect_from_forgery with: :exception
  # CSRF stuff ^

  # verified oauth, etc
  # launch into bigbluebutton
  def launch
    app = lti_app(params[:app])
    uri = URI.parse(app['redirect_uri'])
    site = "#{uri.scheme}://#{uri.host}#{uri.port ? ':' + uri.port.to_s : ''}"
    path = uri.path.split('/')
    root = (path[0].chomp(' ') == '' ? path[1] : path[0]).gsub('/', '')
    redirect_to "#{site}#{root ? '/' + root : ''}/#{params[:app]}/launch?#{params.except(:app, :controller, :action).permit(:sso, :handler).to_query}"
  end
end

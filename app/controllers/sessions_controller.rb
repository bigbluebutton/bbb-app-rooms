class SessionsController < ApplicationController
  include ApplicationHelper

  def new
  end

  def create
    auth_hash = request.env['omniauth.auth']

    # Return error if authentication fails
    redirect_to omniauth_failure_path and return unless auth_hash && auth_hash.uid

    # As authentication did not fail, initialize the session
    session[:uid] = auth_hash.uid
    query = JSON.parse(cookies['launch_params']).to_query
    cookies.delete('launch_params')
    redirect_to "#{launch_url()}?#{query}"
  end

  def failure
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end

end

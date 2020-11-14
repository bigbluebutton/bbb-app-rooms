require 'spaces_api'

class ReportsController < ApplicationController
  include ApplicationHelper
  include SpacesApi

  before_action :find_room
  before_action :check_spaces_credentials
  before_action :find_user
  before_action do
    authorize_user!(:edit, @room)
  end

  # GET /rooms/:id/reports
  def index
    respond_to do |format|
      @reports = get_room_reports(@room)
      format.html { render 'rooms/reports' }
    end
  end

  # GET /rooms/:id/report/download
  def download
    url = report_download_url(@room, params[:period], params[:file_format])
    redirect_to url
  end

  def list_all_files
    list_bucket_files
  end

  def check_spaces_credentials
    unless spaces_configured?
      Rails.logger.error "A Spaces credential is missing from the .env file"
      redirect_back(fallback_location: room_path(@room),
                      notice: t('default.app.spaces_error'))
    end
  end

end
class ErrorsController < ApplicationController
  include ApplicationHelper

  def index
    @error = { code: params[:code], key: t("error.http._#{params[:code]}.code"), message: t("error.http._#{params[:code]}.message"), suggestion: t("error.http._#{params[:code]}.suggestion"), :status => params[:code] }
    respond_to do |format|
      format.html { render :index, status: params[:code] }
      format.json { render json: { error:  @error }, status: @error[:code] }
    end
  end

end

# frozen_string_literal: true

class HealthCheckController < ApplicationController

  def all
    respond_to do |format|
      format.any { render(plain: 'success') }
      format.html
    end
  end

end

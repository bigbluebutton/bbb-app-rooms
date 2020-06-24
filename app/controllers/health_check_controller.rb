# frozen_string_literal: true

class HealthCheckController < ApplicationController
  def all
    render(plain: 'success')
  end
end

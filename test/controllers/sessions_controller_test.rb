# frozen_string_literal: true

require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'should get create' do
    get sessions_create_url
    assert_response :found
  end

  test 'should get failure' do
    get sessions_failure_url
    assert_response :success
  end
end

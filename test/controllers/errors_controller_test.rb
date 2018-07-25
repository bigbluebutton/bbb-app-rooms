require 'test_helper'

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get errors_url(404)
    assert_response :not_found
  end

end

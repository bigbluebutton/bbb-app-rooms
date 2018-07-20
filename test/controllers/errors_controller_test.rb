require 'test_helper'

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get errors_index_url
    assert_response :success
  end

end

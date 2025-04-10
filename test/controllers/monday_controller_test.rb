require "test_helper"

class MondayControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get monday_index_url
    assert_response :success
  end
end

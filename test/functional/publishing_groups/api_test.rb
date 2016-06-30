require File.dirname(__FILE__) + "/../../test_helper"

class PublishingGroups::ApiTest < ActionController::TestCase
  tests PublishingGroupsController

  context "index" do
    setup do
      login_as Factory(:admin)
      get :index, :format => "xml"
    end

    should "render the publishing groups XML" do
      assert_response :success
    end
  end
end

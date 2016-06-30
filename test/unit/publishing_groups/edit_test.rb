require File.dirname(__FILE__) + "/../../test_helper"

# hydra class PublishingGroups::EditTest

class PublishingGroups::EditTest < ActionController::TestCase
  tests PublishingGroupsController
  
  should "have form fields" do
    login_as Factory(:admin)
    publishing_group = Factory(:publishing_group)
    get :edit, :id => publishing_group.id
    assert_response :success
    assert_select "input[type=checkbox][name='publishing_group[daily_deals_available_for_syndication_by_default]']"
  end
  
end
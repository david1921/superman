require File.dirname(__FILE__) + "/../../test_helper"

# hydra class PublishingGroups::UpdateTest

class PublishingGroups::UpdateTest < ActionController::TestCase
  tests PublishingGroupsController
  
  context "daily_deals_available_for_syndication_by_default" do
    setup do
      @publishing_group = Factory(:publishing_group)
      login_as Factory(:admin)
    end
    
    should "be updated" do
      assert !@publishing_group.daily_deals_available_for_syndication_by_default?
      put(:update, :id => @publishing_group.to_param, :publishing_group => {:daily_deals_available_for_syndication_by_default => true})
      assert assigns(:publishing_group)
      assert_redirected_to edit_publishing_group_path(assigns(:publishing_group))
      assert flash[:notice].any?, "Should have flash"
      assert @publishing_group.reload.daily_deals_available_for_syndication_by_default?
    end
  end
  
end
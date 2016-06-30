require File.dirname(__FILE__) + "/../test_helper"

class AffiliatePlacementsControllerTest < ActionController::TestCase
  
  context "#destroy as json" do
    
    setup do
      @admin = Factory :admin
      @affiliate_placement = Factory :affiliate_placement
    end
    
    should "redirect to signin if the user is not authenticated" do
      post :destroy, :id => @affiliate_placement.id, :format => "json"
      assert_response 401
    end
    
    should "soft delete the AffiliatePlacement matching the passed in ID" do      
      login_as_admin
      
      assert_nil @affiliate_placement.deleted_at
      post :destroy, :id => @affiliate_placement.id, :format => "json"
      assert_response :success
      @affiliate_placement.reload
      assert @affiliate_placement.deleted_at.present?
      assert @affiliate_placement.deleted_at.is_a?(ActiveSupport::TimeWithZone)
      assert JSON.parse(@response.body)["affiliate_placement"].present?
    end
    
    should "raise a ActiveRecord::RecordNotFound when the passed in AP id does not exist" do
      login_as_admin
      
      assert_raises(ActiveRecord::RecordNotFound) do
        post :destroy, :id => "doesntexist", :format => "json"
      end
    end
    
  end
  
  protected
  
  def login_as_admin
    @controller.stubs(:current_user).returns(@admin)
  end

end

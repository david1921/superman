require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerPublishingGroupUserTest

class Syndication::DealsControllerPublishingGroupUserTest < ActionController::TestCase
  
  def setup
    @controller = Syndication::DealsController.new
    @publishing_group = Factory(:publishing_group, :self_serve => true)
    @publisher_1 = Factory(:publisher, :publishing_group => @publishing_group)
    @publisher_2 = Factory(:publisher, :publishing_group => @publishing_group)
    @user = Factory(:user, :company => @publishing_group, :allow_syndication_access => true)
    login_as @user
  end
  
  context "without publisher_id parameter" do
    should "be first publisher" do
      get :list
      assert_response :success
      assert_equal @publisher_1, @controller.send(:current_publisher)
    end
  end
  
  context "with publisher_id parameter" do
    should "be first publisher" do
      get :list, :publisher_id => @publisher_2.to_param
      assert_response :success
      assert_equal @publisher_2, @controller.send(:current_publisher)
    end
  end
  
  context "navigation" do
    setup do
      get :list, :publisher_id => @publisher_2.to_param
    end
    
    should "render correct context with publisher_id parameter" do
      assert_select "#site_nav" do
        assert_select "li.current:nth-child(1)" do
          assert_select "a[href='#{list_syndication_deals_path(:publisher_id => @publisher_2.to_param)}']", :text => I18n.t('browse_deals')
        end
        assert_select "li:nth-child(2)" do
          assert_select "a[href='#{edit_syndication_user_path(@user.id, :publisher_id => @publisher_2.to_param)}']", :text => I18n.t('my_account')
        end
        assert_select "li:nth-child(3)" do
          assert_select "a[href='#{syndication_logout_path}']", :text => I18n.t('logout')
        end
        assert_select "a[href='#{root_path}']", :text => "Manage Deals"
      end
    end
    
    should "render the appropriate view by links" do
      assert_select "#view_select" do
        assert_select "p", :text => "View:"
        assert_select "ul#view_buttons" do
          assert_select "li:nth-child(1)" do
            assert_select "a[href*='publisher_id=#{@publisher_2.to_param}']", :text => "Grid"
          end
          assert_select "li.current:nth-child(2)" do
            assert_select "a[href*='publisher_id=#{@publisher_2.to_param}']", :text => "List"
          end
          assert_select "li:nth-child(3)" do
            assert_select "a[href*='publisher_id=#{@publisher_2.to_param}']", :text => "Calendar"
          end
          assert_select "li:nth-child(4)" do
            assert_select "a[href*='publisher_id=#{@publisher_2.to_param}']", :text => "Map"
          end
        end
      end
    end
    
    should "have publisher change form" do
      assert_select "form[id='publisher_form']", :count => 1 do
        assert_select "option[value=#{@publisher_1.id}]"
        assert_select "option[value=#{@publisher_2.id}]"
      end
    end
  end
  
end

require File.dirname(__FILE__) + "/../../test_helper"

class FacebookHelperTest < ActionView::TestCase
  
  include DailyDealHelper

  context "facebook_page_url" do
    setup do
      @publishing_group_page = "http://www.facebook.com/CoolPublishing"
      @publishing_group = Factory(:publishing_group, :facebook_page_url => @publishing_group_page)
      @publisher_facebook_page = "http://www.facebook.com/CoolDetroit"
      @publisher = Factory(:publisher, :publishing_group => @publishing_group, :facebook_page_url => @publisher_facebook_page)
    end
    should "return publisher's facebook_page_url even when publishing_group's facebook_page_url" do
      assert_equal @publisher_facebook_page, facebook_page_url(@publisher)
    end
    should "return publishing_group's when publisher's is nil" do
      @publisher.facebook_page_url = nil
      @publisher.save!
      assert_equal @publishing_group_page, facebook_page_url(@publisher)                
    end
  end

end

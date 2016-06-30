require File.dirname(__FILE__) + "/../../test_helper"

class DailyRevenueSharingAgreementTest < ActiveSupport::TestCase
  
  context "with publisher agreement only" do
    setup do
      @daily_deal = Factory(:daily_deal_for_syndication)
      @agreement = Factory(:syndication_revenue_sharing_agreement, :agreement => @daily_deal.publisher)
      @accountant = Factory(:accountant)
    end
    
    should "return publisher agreement" do
      assert_equal @agreement, @daily_deal.parent_syndication_revenue_sharing_agreement
    end
  end
  
  context "with publishing group agreement only" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher)
      @agreement = Factory(:syndication_revenue_sharing_agreement, :agreement => @publishing_group)
      @accountant = Factory(:accountant)
    end
    
    should "return publishing group agreement" do
      assert_equal @agreement, @daily_deal.parent_syndication_revenue_sharing_agreement
    end
  end
  
  context "with publisher and publishing group agreement" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher)
      @publishing_group_agreement = Factory(:syndication_revenue_sharing_agreement, :agreement => @publishing_group)
      @publisher_agreement = Factory(:syndication_revenue_sharing_agreement, :agreement => @publisher)
      @accountant = Factory(:accountant)
    end
    
    should "return publisher agreement" do
      assert_equal @publisher_agreement, @daily_deal.parent_syndication_revenue_sharing_agreement
    end
  end
end
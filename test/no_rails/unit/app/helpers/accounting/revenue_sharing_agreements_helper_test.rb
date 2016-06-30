require File.dirname(__FILE__) + "/../../helpers_helper"

class Accounting::RevenueSharingAgreementsHelperTest < Test::Unit::TestCase

  class MockHelper
    include Accounting::RevenueSharingAgreementsHelper
  end
  
  context "platform_revenue_sharing_agreement_edit_url" do
    setup do
      @helper = MockHelper.new
      @agreement = mock("platform_revenue_sharing_agreement")
      @publishing_group = mock("publishing_group")
      @publisher = mock("publisher")
      @daily_deal = mock("daily_deal")
    end
    
    context "publishing group present" do
      should "return publishing group url" do
        @publishing_group.expects(:present?).returns(true)
        @helper.stubs(:platform_publishing_group_revenue_sharing_agreement_edit_url).with(@publishing_group, @agreement)
        @helper.platform_revenue_sharing_agreement_edit_url(@publishing_group, @publisher, @daily_deal, @agreement)
      end
    end
    
    context "publisher present" do
      should "return publisher url" do
        @publishing_group.expects(:present?).returns(false)
        @publisher.expects(:present?).returns(true)
        @helper.stubs(:platform_publisher_revenue_sharing_agreement_edit_url).with(@publisher, @agreement)
        @helper.platform_revenue_sharing_agreement_edit_url(@publishing_group, @publisher, @daily_deal, @agreement)
      end
    end

    context "daily_deal present" do
      should "return daily_deal url" do
        @publishing_group.expects(:present?).returns(false)
        @publisher.expects(:present?).returns(false)
        @daily_deal.expects(:present?).returns(true)
        @helper.stubs(:daily_deal_platform_revenue_sharing_agreement_url).with(@daily_deal)
        @helper.platform_revenue_sharing_agreement_edit_url(@publishing_group, @publisher, @daily_deal, @agreement)
      end
    end
  end
  
  context "platform_publishing_group_revenue_sharing_agreement_edit_url" do
    setup do
      @helper = MockHelper.new
      @agreement = mock("platform_revenue_sharing_agreement")
      @publishing_group = mock("publishing_group")
    end
    
    should "return collection url when new agreement" do
      @agreement.expects(:new_record?).returns(true)
      @helper.stubs(:publishing_group_platform_revenue_sharing_agreements_url).with(@publishing_group)
      @helper.platform_publishing_group_revenue_sharing_agreement_edit_url(@publishing_group, @agreement)
    end
    
    should "return member url when existing agreement" do
      @agreement.expects(:new_record?).returns(false)
      @helper.stubs(:publishing_group_platform_revenue_sharing_agreement_url).with(@publishing_group, @agreement)
      @helper.platform_publishing_group_revenue_sharing_agreement_edit_url(@publishing_group, @agreement)
    end
  end
  
  context "platform_publisher_revenue_sharing_agreement_edit_url" do
    setup do
      @helper = MockHelper.new
      @agreement = mock("platform_revenue_sharing_agreement")
      @publisher = mock("publisher")
    end
    
    should "return collection url when new agreement" do
      @agreement.expects(:new_record?).returns(true)
      @helper.stubs(:publisher_platform_revenue_sharing_agreements_url).with(@publisher)
      @helper.platform_publisher_revenue_sharing_agreement_edit_url(@publisher, @agreement)
    end
    
    should "return member url when existing agreement" do
      @agreement.expects(:new_record?).returns(false)
      @helper.stubs(:publisher_platform_revenue_sharing_agreement_url).with(@publisher, @agreement)
      @helper.platform_publisher_revenue_sharing_agreement_edit_url(@publisher, @agreement)
    end
  end
  
  context "syndication_revenue_sharing_agreement_edit_url" do
    setup do
      @helper = MockHelper.new
      @agreement = mock("syndication_revenue_sharing_agreement")
      @publishing_group = mock("publishing_group")
      @publisher = mock("publisher")
      @daily_deal = mock("daily_deal")
    end
    
    context "publishing group present" do
      should "return publishing group url" do
        @publishing_group.expects(:present?).returns(true)
        @helper.stubs(:syndication_publishing_group_revenue_sharing_agreement_edit_url).with(@publishing_group, @agreement)
        @helper.syndication_revenue_sharing_agreement_edit_url(@publishing_group, @publisher, @daily_deal, @agreement)
      end
    end
    
    context "publishing group present" do
      should "return publisher url" do
        @publishing_group.expects(:present?).returns(false)
        @publisher.expects(:present?).returns(true)
        @helper.stubs(:syndication_publisher_revenue_sharing_agreement_edit_url).with(@publisher, @agreement)
        @helper.syndication_revenue_sharing_agreement_edit_url(@publishing_group, @publisher, @daily_deal, @agreement)
      end
    end
    
    context "daily_deal present" do
      should "return daily_deal url" do
        @publishing_group.expects(:present?).returns(false)
        @publisher.expects(:present?).returns(false)
        @daily_deal.expects(:present?).returns(true)
        @helper.stubs(:daily_deal_syndication_revenue_sharing_agreement_url).with(@daily_deal)
        @helper.syndication_revenue_sharing_agreement_edit_url(@publishing_group, @publisher, @daily_deal, @agreement)
      end
    end
  end
  
  context "syndication_publishing_group_revenue_sharing_agreement_edit_url" do
    setup do
      @helper = MockHelper.new
      @agreement = mock("syndication_revenue_sharing_agreement")
      @publishing_group = mock("publishing_group")
    end
    
    should "return collection url when new agreement" do
      @agreement.expects(:new_record?).returns(true)
      @helper.stubs(:publishing_group_syndication_revenue_sharing_agreements_url).with(@publishing_group)
      @helper.syndication_publishing_group_revenue_sharing_agreement_edit_url(@publishing_group, @agreement)
    end
    
    should "return member url when existing agreement" do
      @agreement.expects(:new_record?).returns(false)
      @helper.stubs(:publishing_group_syndication_revenue_sharing_agreement_url).with(@publishing_group, @agreement)
      @helper.syndication_publishing_group_revenue_sharing_agreement_edit_url(@publishing_group, @agreement)
    end
  end
  
  context "syndication_publisher_revenue_sharing_agreement_edit_url" do
    setup do
      @helper = MockHelper.new
      @agreement = mock("platform_revenue_sharing_agreement")
      @publisher = mock("publisher")
    end
    
    should "return collection url when new agreement" do
      @agreement.expects(:new_record?).returns(true)
      @helper.stubs(:publisher_syndication_revenue_sharing_agreements_url).with(@publisher)
      @helper.syndication_publisher_revenue_sharing_agreement_edit_url(@publisher, @agreement)
    end
    
    should "return member url when existing agreement" do
      @agreement.expects(:new_record?).returns(false)
      @helper.stubs(:publisher_syndication_revenue_sharing_agreement_url).with(@publisher, @agreement)
      @helper.syndication_publisher_revenue_sharing_agreement_edit_url(@publisher, @agreement)
    end
  end
  
end

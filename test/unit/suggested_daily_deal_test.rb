require File.dirname(__FILE__) + "/../test_helper"

class SuggestedDailyDealTest < ActiveSupport::TestCase
  should validate_presence_of :publisher
  should validate_presence_of :description

  context "sending email" do
    context "given publisher.suggested_daily_deal_email_address" do
      setup do
        @publisher = Factory(:publisher, :suggested_daily_deal_email_address => "foo@example.com")
        @suggested_daily_deal = Factory.build(:suggested_daily_deal, :publisher => @publisher)
      end

      should "send email when suggested deal is created" do
        PublishersMailer.expects(:deliver_suggested_daily_deal).at_least_once
        @suggested_daily_deal.save
      end
    end

    context "given no publisher.suggested_daily_deal_email_address" do
      setup do
        @publisher = Factory(:publisher, :suggested_daily_deal_email_address => nil)
        @suggested_daily_deal = Factory.build(:suggested_daily_deal, :publisher => @publisher)
      end

      should "not send email when suggested deal is created" do
        PublishersMailer.expects(:deliver_suggested_daily_deal).never
        @suggested_daily_deal.save
      end
    end
  end
end

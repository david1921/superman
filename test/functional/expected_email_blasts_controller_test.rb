require File.dirname(__FILE__) + "/../test_helper"

class ExpectedEmailBlastsControllerTest < ActionController::TestCase
  context "#index" do
    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
    end

    should "assign expected email blasts for publisher" do
      Timecop.freeze do
        daily_deal = Factory(:daily_deal, :featured => true, :enable_daily_email_blast => true, :advertiser => @advertiser)
        daily_deal.tap do |deal|
          deal.start_at = daily_deal.publisher.send_todays_email_blast_at - 23.hours
          deal.save
        end
        get :index, :publisher_label => daily_deal.publisher.label
        expected = ExpectedEmailBlast.new(:daily_deal => daily_deal, :blast_at => daily_deal.send_todays_email_blast_at)
        assert_equal [expected], assigns(:expected_email_blasts)
      end
    end

    should "not return a deal that starts after the blast time" do
      Timecop.freeze do
        daily_deal = Factory(:daily_deal, :featured => true, :enable_daily_email_blast => true)
        daily_deal.tap do |deal|
          deal.start_at = daily_deal.publisher.send_todays_email_blast_at + 1.hour
          deal.save
        end
        assert daily_deal.start_at > daily_deal.publisher.send_todays_email_blast_at
        get :index, :publisher_label => daily_deal.publisher.label
        assert_equal [], assigns(:expected_email_blasts)
      end
    end

    should "raise an exception if unknown publisher is specified" do
      assert_raise(ActiveRecord::RecordNotFound) do
        get :index, :publisher_label => "unknown"
      end
    end
  end
end

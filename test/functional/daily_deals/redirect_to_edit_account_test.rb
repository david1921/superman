require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::RedirectToEditAccountTest < ActionController::TestCase
  tests DailyDealsController

  context "PublisherGroup#enable_force_valid_consumers" do

    setup do
      @publishing_group = Factory(:publishing_group, :enable_force_valid_consumers => true)
      @publisher  = Factory(:publisher, :publishing_group => @publishing_group)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
      @consumer   = Factory(:consumer, :publisher => @publisher)
      @consumer.activate!
      login_as @consumer
    end

    context "invalid consumers" do
      setup do
        @consumer.update_attribute :agree_to_terms, false # no longer valid?
        assert !@consumer.valid?
      end

      should "redirect to the user edit page" do
        get :show, :id => @daily_deal.to_param
        assert_redirected_to "http://test.host/publishers/#{@publisher.to_param}/consumers/#{@consumer.to_param}/edit"
      end

      should "not redirect because the publishing group doesn't enforce valid consumers" do
        @publishing_group.update_attributes! :enable_force_valid_consumers => false
        get :show, :id => @daily_deal.to_param
        assert_response :success
      end
    end

    context "valid consumers" do
      should "not redirect because the user is valid" do
        get :show, :id => @daily_deal.to_param
        assert_response :success
      end
    end
  end
end
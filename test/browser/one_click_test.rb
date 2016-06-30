require File.dirname(__FILE__) + "/browser_test"
require File.dirname(__FILE__) + "/helpers/purchase_test_helper"
require "shoulda"

class OneClickTest < BrowserTest
  include PurchaseTestHelper
  include ActionView::Helpers::TextHelper
  include OneClickPurchasesHelper

  def setup
    @port = 8080
    Capybara.server_port = @port
    Capybara.current_driver = Capybara.javascript_driver
    Factory(:country, :code => 'US') # publishers use US by default
    @publisher = Factory(:publisher, :production_daily_deal_host => "localhost:#{@port}")
  end

  def teardown
    visit "/publishers/#{@publisher.id}/daily_deal/logout"
  end

  context "on a deal not requiring a shipping address" do
    setup do
      @deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher), :requires_shipping_address => false)
      # "Deal of the day" page
      visit "/daily_deals/#{@deal.id}/one_click_purchases/new"
    end

    should "always show the billing address fields" do
      assert find("#billing_details").visible?
    end

    should "never show the use shipping address checkbox" do
      assert !page.has_css?("#transaction_custom_fields_use_shipping_address_as_billing_address")
    end

    context "new consumer buys deal" do
      should "not display shipping fields" do
        click_link "Sign Up"
        assert !page.has_css?("#shipping_address")
      end
    end

    context "existing consumer buys deal" do
      setup do
        @consumer = Factory(:consumer, :publisher => @publisher)
      end

      should "not display shipping fields" do
        # "Review and Buy"
        click_link "Sign In"
        assert !page.has_css?("#shipping_address")
        page.driver.options[:resynchronize] = true
        fill_in_sign_in_fields(@consumer)
        click_button "Sign In"
        assert !page.has_css?("#shipping_address")
      end
    end

  end

  context "on a deal requiring shipping address" do

    setup do
      @deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher), :requires_shipping_address => true)
      @stubbed_consumer = Factory.stub(:consumer, :publisher => @publisher)
      visit "/daily_deals/#{@deal.id}/one_click_purchases/new"
    end

    should "have billing details div hidden by default and checkbox is checked by default" do
      assert !find("#billing_details").visible?
      assert find("#transaction_custom_fields_use_shipping_address_as_billing_address").checked?
    end

    should "show billing details div if box is unchecked" do
      fill_in_payment_fields(@stubbed_consumer, true)

      uncheck "transaction_custom_fields_use_shipping_address_as_billing_address"

      assert find("#billing_details").visible?
    end

    should "hide billing details div if box is checked" do
      fill_in_payment_fields(@stubbed_consumer, true)

      uncheck "transaction_custom_fields_use_shipping_address_as_billing_address"
      check "transaction_custom_fields_use_shipping_address_as_billing_address"

      assert !find("#billing_details").visible?
    end

    context "new consumer buys deal" do
      setup do

        # "Review and Buy"
        fill_in_registration_fields(@stubbed_consumer)
        fill_in_shipping_fields
      end

      should "display shipping fields" do

        fill_in_payment_fields(@stubbed_consumer, true)

        click_button "Buy Now"

        sleep(5)
        # "Thank you" page
        assert_thank_you_page

        # Database checks
        consumer = Consumer.last
        assert_equal @stubbed_consumer.email,consumer.email
        assert_not_nil DailyDealPurchase.find_by_daily_deal_id_and_consumer_id(@deal.id, consumer.id)
      end
    end

    context "existing consumer buys deal" do
      setup do
        @consumer = Factory(:consumer, :publisher => @publisher)
      end

      context "without saved recipients" do
        should "display shipping address fields" do
        	total_daily_deal_purchases = DailyDealPurchase.count

          # "Review and Buy"
          click_link "Sign In"
          page.driver.options[:resynchronize] = true
          fill_in_sign_in_fields(@consumer)
          click_button "Sign In"

          fill_in_shipping_fields
          fill_in_payment_fields(@consumer, true)

          click_button "Buy Now"

          # "Thank you" page
          assert_thank_you_page
          assert_equal total_daily_deal_purchases + 1, DailyDealPurchase.count, "daily deal purchases should increase by 1"
        end
      end

      context "with saved recipients" do
        setup do
          @recipient1 = Factory(:recipient, :addressable => @consumer)
          @recipient2 = Factory(:recipient, :addressable => @consumer)
        end

        should "display recipient select field" do

          total_daily_deal_purchases = DailyDealPurchase.count

          # "Review and Buy"
          click_link "Sign In"
          page.driver.options[:resynchronize] = true
          fill_in_sign_in_fields(@consumer)
          click_button "Sign In"

          select text_for_recipient_select_option(@recipient2), :from => 'consumer_recipient'

          fill_in_payment_fields(@consumer, true)

          click_button "Buy Now"

          # "Thank you" page
          assert_thank_you_page
          assert_equal total_daily_deal_purchases + 1, DailyDealPurchase.count, "daily deal purchases should increase by 1"
        end
      end
    end
  end
end

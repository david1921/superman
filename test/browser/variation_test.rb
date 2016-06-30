require File.dirname(__FILE__) + "/browser_test"
require 'shoulda'

class VariationTest < BrowserTest
	include Helpers::PurchaseHelper

  def setup
  	@port = 8080
    Capybara.server_port = @port
    Capybara.current_driver = Capybara.javascript_driver
    Factory(:country, :code => 'US') # publishers use US by default
  end

  context "daily deal with variations on main deal page" do

    setup do
      @publisher        = Factory(:publisher, :enable_daily_deal_variations => true, :allow_voucher_shipping => true, :production_daily_deal_host => "localhost:#{@port}", :production_host => "localhost:#{@port}")
      @deal             = Factory(:daily_deal, :publisher => @publisher)
      @variation_1      = Factory(:daily_deal_variation, :daily_deal => @deal, :value_proposition => "Value Prop 1", :price => 20, :value => 40)
      @variation_2      = Factory(:daily_deal_variation, :daily_deal => @deal, :value_proposition => "Value Prop 2", :price => 40, :value => 80)
    end

    context "on main deal page" do

      should "be able to open and close popup menu" do
        visit "/publishers/#{@publisher.label}/deal-of-the-day"

        page.find(".dd_variations_button").click
        wait_until{ page.find(".dd_variations_menu").visible? }
        assert page.find(".dd_variations_menu").visible?, "clicking on button should open menu"

        page.find(".dd_variations_button").click
        wait_until{ !page.find(".dd_variations_menu").visible? }
        assert !page.find(".dd_variations_menu").visible?, "clicking on button again should close menu"

        page.find(".dd_variations_button").click
        wait_until{ page.find(".dd_variations_menu").visible? }
        assert page.find(".dd_variations_menu").visible?, "clicking on button again should re-open menu"

        page.find("body").click
        wait_until{ !page.find(".dd_variations_menu").visible? }
        assert !page.find(".dd_variations_menu").visible?, "clicking outside of the menu should close menu"
      end

      should "be able to select variation 1" do

        visit "/publishers/#{@publisher.label}/deal-of-the-day"
        assert page.has_css?(".dd_variations_button"), "Should have '.dd_variations_button' button"
        assert page.has_css?(".dd_variations_menu"), "Should have '.dd_variations_menu'"

        assert_equal page.all(".dd_variations_menu").size, 1
        wait_until{ !page.find(".dd_variations_menu").visible? }
        assert !page.find(".dd_variations_menu").visible?

        page.find(".dd_variations_button").click
        wait_until{ page.find(".dd_variations_menu").visible? }
        assert page.find(".dd_variations_menu").visible?

        page.find(".dd_variations_menu").find("table tr:nth-child(1) a").click
        assert_equal "/daily_deals/#{@deal.id}/daily_deal_purchases/new?daily_deal_variation_id=#{@variation_1.id}", current_path_with_params

        assert_equal @variation_1.line_item_name, page.find("table#new_daily_deal_purchase tr:nth-child(2) td.description").text

        # Fulfillment options
        choose "daily_deal_purchase_fulfillment_method_email"

        # "Review and Buy"
        fill_in_registration_form

        click_button "Review and Buy"

        # Braintree payment form
        fill_in_payment_form
        click_button "Buy Now"

        # "Thank you" page
        assert page.has_content?("Thank You")
        assert page.has_link?("View your orders")

        page.click_on("View your orders")
        assert_equal @variation_1.line_item_name, page.find("table.daily_deal_purchase tr:nth-child(2) td.description").text

      end

      should "be able to select variation 2" do

        visit "/publishers/#{@publisher.label}/deal-of-the-day"
        assert page.has_css?(".dd_variations_button"), "Should have '.dd_variations_button' button"
        assert page.has_css?(".dd_variations_menu"), "Should have '.dd_variations_menu'"

        assert_equal page.all(".dd_variations_menu").size, 1
        assert !page.find(".dd_variations_menu").visible?

        page.find(".dd_variations_button").click
        wait_until{ page.find(".dd_variations_menu").visible? }
        assert page.find(".dd_variations_menu").visible?

        page.find(".dd_variations_menu").find("table tr:nth-child(2) a").click
        assert_equal "/daily_deals/#{@deal.id}/daily_deal_purchases/new?daily_deal_variation_id=#{@variation_2.id}", current_path_with_params

        assert_equal @variation_2.line_item_name, page.find("table#new_daily_deal_purchase tr:nth-child(2) td.description").text

        # Fulfillment options
        choose "daily_deal_purchase_fulfillment_method_email"

        # "Review and Buy"
        fill_in_registration_form

        click_button "Review and Buy"

        # Braintree payment form
        fill_in_payment_form
        click_button "Buy Now"

        # "Thank you" page
        assert page.has_content?("Thank You")
        assert page.has_link?("View your orders")
        page.click_on("View your orders")
        assert_equal @variation_2.line_item_name, page.find("table.daily_deal_purchase tr:nth-child(2) td.description").text
      end   


    end

    context "on all deals page" do

      setup do
        @sd_1               = Factory(:side_daily_deal, :publisher => @publisher)
        @sd_1_variation_1   = Factory(:daily_deal_variation, :daily_deal => @sd_1, :value_proposition => "Side Deal 1 Value Prop 1", :price => 20, :value => 40)
        @sd_1_variation_2   = Factory(:daily_deal_variation, :daily_deal => @sd_1, :value_proposition => "Side Deal 2 Value Prop 2", :price => 40, :value => 80)

        @sd_2               = Factory(:side_daily_deal, :publisher => @publisher)
        @sd_2_variation_1   = Factory(:daily_deal_variation, :daily_deal => @sd_2, :value_proposition => "Side Deal 2 Value Prop 1", :price => 10, :value => 20)
        @sd_2_variation_2   = Factory(:daily_deal_variation, :daily_deal => @sd_2, :value_proposition => "Side Deal 2 Value Prop 2", :price => 15, :value => 30)
      end

      should "have three deals on the page" do
        visit "/publishers/#{@publisher.label}/daily_deals"

        assert @deal.value_proposition, page.find("#daily_deal_content_box .daily_deal:nth-child(1) .deal_details h5").text
        assert @sd_1.value_proposition, page.find("#daily_deal_content_box .daily_deal:nth-child(2) .deal_details h5").text
        assert @sd_2.value_proposition, page.find("#daily_deal_content_box .daily_deal:nth-child(3) .deal_details h5").text
      end

      should "be able to open and close menu on multiple side deals" do
        visit "/publishers/#{@publisher.label}/daily_deals"

        assert !page.find("#daily_deal_content_box .daily_deal:nth-child(1) .dd_variations_menu").visible?, "initial @deal menu should be close"
        assert !page.find("#daily_deal_content_box .daily_deal:nth-child(2) .dd_variations_menu").visible?, "initial @deal menu should be close"
        assert !page.find("#daily_deal_content_box .daily_deal:nth-child(3) .dd_variations_menu").visible?, "initial @deal menu should be close"

      end

    end


  end

end
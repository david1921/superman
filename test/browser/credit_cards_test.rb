require File.dirname(__FILE__) + "/browser_test"
require File.dirname(__FILE__) + "/helpers/browser_test_helper"
require "shoulda"
require "ruby-debug"

class CreditCardsTest < BrowserTest
  include BrowserTestHelper

  context "credit card management" do
    setup do
      @port = 8080
      Capybara.server_port = @port
      Capybara.current_driver = Capybara.javascript_driver
      Factory(:country, :code => 'US', :name => "United States")
      Factory(:country, :code => 'CA', :name => "Canada")
      @consumer = Factory(:consumer)
      login_consumer @consumer
    end

    context "removing a credit card"  do
      setup do
        @card = @consumer.credit_cards.create!(:token => "abc123", :card_type => "Visa", :bin => "123456", :last_4 => "9876")
        visit "/consumers/#{@consumer.id}/credit_cards"
      end

      should "show confirmation dialog when remove is clicked" do
        find("#credit_card_#{@card.id} .remove").click
        assert find("#credit_card_#{@card.id} .confirm_delete").visible?
      end

      should "hide confirmation dialog when cancel is clicked" do
        find("#credit_card_#{@card.id} .remove").click
        find(:xpath, "//li[@id='credit_card_#{@card.id}']//button[@role='cancel']").click
        assert !find("#credit_card_#{@card.id} .confirm_delete").visible?
      end

      should "hide confirmation dialog when anything but confirm is clicked" do
        find("#credit_card_#{@card.id} .remove").click
        find("#credit_card_#{@card.id}").click
        assert !find("#credit_card_#{@card.id} .confirm_delete").visible?
      end

      should "remove credit card from page when remove and confirm are clicked" do
        Braintree::CreditCard.expects(:delete).with("abc123").returns(true)

        find("#credit_card_#{@card.id} .remove").click
        find(:xpath, "//li[@id='credit_card_#{@card.id}']//button[@role='confirm']").click
        assert has_no_xpath?("//li[@id='#credit_card_#{@card.id}']")
      end

    end
  end
end
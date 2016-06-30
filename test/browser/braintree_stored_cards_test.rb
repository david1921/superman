require File.dirname(__FILE__) + "/browser_test"
require File.dirname(__FILE__) + "/helpers/purchase_test_helper"

class BrainTreeStoredCardsTest < BrowserTest

  include PurchaseTestHelper

  def setup
    @port = 8080
    Capybara.server_port = @port
    Capybara.current_driver = Capybara.javascript_driver
    Factory(:country, :code => 'US', :name => "United States")
    Factory(:country, :code => 'CA', :name => "Canada")
  end

  test "Store this card checkbox when use_vault is true" do
    @publishing_group = Factory(:publishing_group, :use_vault => true)
    @publisher = Factory(:publisher, :publishing_group => @publishing_group, :production_daily_deal_host => "localhost:#{@port}")
    @deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher))
    @consumer = Factory(:consumer)

    # "Deal of the day" page
    visit "/publishers/#{@deal.publisher.label}/deal-of-the-day"
    assert page.has_css?("#buy_now_button"), "Should have 'Buy Now' button"
    click_link "buy_now_button"

    assert page.has_css?("#review_button"), "Should have 'Review and Buy' Button"

    fill_in_registration_fields(@consumer)
    click_button "Review and Buy"

    assert page.find("#transaction_options_store_in_vault_on_success").checked?, "Should have 'Save this card' Checked"
  end

  test "javascript on payment method radio buttons with existing stored credit card"  do
    @publishing_group = Factory(:publishing_group, :use_vault => true)
    @publisher = Factory(:publisher, :publishing_group => @publishing_group, :production_daily_deal_host => "localhost:#{@port}")
    @deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher))
    @consumer = Factory(:consumer, :publisher => @publisher, :in_vault => true)
    credit_card = Factory(:credit_card, :consumer => @consumer)

    # "Deal of the day" page
    visit "/publishers/#{@deal.publisher.label}/deal-of-the-day"
    assert page.has_css?("#buy_now_button"), "Should have 'Buy Now' button"
    click_link "buy_now_button"

    assert page.has_css?("#review_button"), "Should have 'Review and Buy' Button"

    click_link "Sign In"
    page.driver.options[:resynchronize] = true
    fill_in_sign_in_fields(@consumer)
    click_button "Sign In"

    click_link "buy_now_button"

    click_button "Review and Buy"

    assert page.has_css?("#choose_payment_method_radio"), "Should have 'Use Stored Card' radio button"
    assert page.find("#choose_payment_method_radio").checked?, "Should have 'Choose Stored Card' radio checked"

    assert page.has_css?("#add_new_card_radio"), "Should have 'Store new Card' radio button"
    assert !page.find("#add_new_card_radio").checked?, "Should NOT have 'Store new Card' radio checked"

    assert page.find("#token_select").visible?, "Should have 'stored card' select box visible"
    assert page.find("#transparent_redirect_stored_cards_form_abc123").visible?, "Should have 'transparent_redirect_stored_cards_form_abc123' form visible"

    assert !page.find("#transparent_redirect_form").visible?, "Should NOT have 'transparent_redirect_form' form visible"
    assert !page.find("#transaction_billing_first_name").visible?, "Should NOT have 'transaction_billing_first_name' field visible"
    assert !page.find("#transaction_credit_card_cardholder_name").visible?, "Should NOT have 'transaction_credit_card_cardholder_name' field visible"

    choose "add_new_card_radio"

    assert !page.find("#choose_payment_method_radio").checked?, "Should NOT have 'Choose Stored Card' radio checked"

    assert page.find("#add_new_card_radio").checked?, "Should have 'Store new Card' radio checked"

    assert !page.find("#token_select").visible?, "Should NOT have 'stored card' select box visible"
    assert !page.find("#transparent_redirect_stored_cards_form_abc123").visible?, "Should have 'transparent_redirect_stored_cards_form_abc123' form visible"

    assert page.find("#transparent_redirect_form").visible?, "Should have 'transparent_redirect_form' form visible"
    assert page.find("#transaction_billing_first_name").visible?, "Should have 'transaction_billing_first_name' field visible"
    assert page.find("#transaction_credit_card_cardholder_name").visible?, "Should have 'transaction_credit_card_cardholder_name' field visible"

  end
end

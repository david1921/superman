require File.dirname(__FILE__) + "/browser_test"
require File.dirname(__FILE__) + "/helpers/purchase_test_helper"
require 'shoulda'

# ruby -Itest test/browser/purchase_test.rb
#
# Options:
#  CAPYBARA_DRIVER=selenium to use Selenium-controlled web browser instead of default in-process Rack driver
#
class PurchaseTest < BrowserTest

  include PurchaseTestHelper

  def setup
    @port = 8080
    Capybara.server_port = @port

    Capybara.current_driver = Capybara.javascript_driver

    Factory(:country, :code => 'US', :name => "United States")
    Factory(:country, :code => 'CA', :name => "Canada")
  end

  test "new customer buys deal" do
    @publisher = Factory(:publisher, :production_daily_deal_host => "localhost:#{@port}")
    @deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher))
    stubbed_consumer = Factory.stub(:consumer)

    # "Deal of the day" page
    visit "/publishers/#{@deal.publisher.label}/deal-of-the-day"
    assert page.has_css?("#buy_now_button"), "Should have 'Buy Now' button"
    click_link "buy_now_button"

    # "Review and Buy"
    fill_in_registration_fields(stubbed_consumer)
    click_button "Review and Buy"

    # Braintree payment form
    fill_in_payment_fields(stubbed_consumer)
    click_button "Buy Now"

    # "Thank you" page
    assert_thank_you_page

    # Database checks
    consumer = Consumer.last
    assert_equal stubbed_consumer.email, consumer.email
    assert_not_nil DailyDealPurchase.find_by_daily_deal_id_and_consumer_id(@deal.id, consumer.id)
  end

  test "new customer buys deal with mailed vouchers" do
    @publisher = Factory(:publisher, :production_daily_deal_host => "localhost:#{@port}", :allow_voucher_shipping => true)
    @deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher), :price => 10)
    stubbed_consumer = Factory.stub(:consumer)

    # "Deal of the day" page
    visit "/publishers/#{@deal.publisher.label}/deal-of-the-day"
    click_link "buy_now_button"

    # Fulfillment options
    choose "daily_deal_purchase_fulfillment_method_ship"
    fill_in_mailing_address

    # "Review and Buy"
    fill_in_registration_fields(stubbed_consumer)
    click_button "Review and Buy"

    # Braintree payment form
    fill_in_payment_fields(stubbed_consumer)
    click_button "Buy Now"

    # "Thank you" page
    assert_thank_you_page

    # Database checks
    consumer = Consumer.last
    assert_equal stubbed_consumer.email, consumer.email
    purchase = DailyDealPurchase.find_by_daily_deal_id_and_consumer_id(@deal.id, consumer.id)
    assert_not_nil purchase
    assert_not_nil purchase.mailing_address
    assert_equal "ship", purchase.fulfillment_method
    assert_equal 3, purchase.voucher_shipping_amount
    assert_equal 3, purchase.voucher_shipping_amount
    assert_equal 10 + 3, purchase.total_paid
  end

  test "travelsavers deal payment form validation for the default theme" do
    deal = Factory(:travelsavers_daily_deal)
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => deal)
    assert !File.exists?(Rails.root.join("app/views/themes/#{deal.publisher.label}")), "didn't expect publisher to have theme"
    assert_load_test_data_button_is_present_and_ts_checkout_form_validation_works(daily_deal_purchase)
  end
  
  test "travelsavers deal payment form validation for the roaringlion theme" do
    deal = Factory(:travelsavers_daily_deal)
    deal.publisher.update_attributes! :parent_theme => "roaringlion"
    daily_deal_purchase = Factory(:pending_daily_deal_purchase, :daily_deal => deal)
    assert_load_test_data_button_is_present_and_ts_checkout_form_validation_works(daily_deal_purchase)
  end
  
  test "travelsavers deal payment form validation for entercom's theme" do
    daily_deal_purchase = create_purchase_for_publisher_within_group("entercom-providence", "entercomnew")
    assert_load_test_data_button_is_present_and_ts_checkout_form_validation_works(daily_deal_purchase)    
  end
  
  test "travelsavers deal payment form validation for ocregister's theme" do
    daily_deal_purchase = create_purchase_for_publisher_within_group("ocregister", "freedom")
    assert_load_test_data_button_is_present_and_ts_checkout_form_validation_works(daily_deal_purchase)
  end
  
  test "travelsavers deal payment form validation for offto" do
    daily_deal_purchase = create_purchase_for_publisher_within_group("offto", "offto-sixseats")
    assert_load_test_data_button_is_present_and_ts_checkout_form_validation_works(daily_deal_purchase)
  end

  test "cybersource purchase confirm form US zip code validation" do
    entertainment = Factory :publishing_group, :label => "entertainment"
    publisher = Factory :publisher_using_cybersource, :publishing_group => entertainment
    deal = Factory :daily_deal, :publisher => publisher
    consumer = Factory :billing_address_consumer, :publisher => publisher
    daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    fake_cybersource_form_path = "/fake/cybersource/path"

    load_confirm_page_for_cybersource_purchase(daily_deal_purchase)
    stub_cybersource_order_form_action(fake_cybersource_form_path)
    fill_out_cybersource_payment_form_with_invalid_zip_code
    click_buy_now
    ensure_still_on_purchase_confirmation_page(daily_deal_purchase)
    ensure_cybersource_postal_code_validation_error
    fix_zip_code
    click_buy_now
    ensure_cybersource_form_successfully_submitted(fake_cybersource_form_path)
  end

  test "cybersource purchase confirm form Canadian postal code validation" do
    entertainment = Factory :publishing_group, :label => "entertainment"
    publisher = Factory :publisher_using_cybersource, :publishing_group => entertainment
    deal = Factory :daily_deal, :publisher => publisher
    consumer = Factory :billing_address_consumer, :publisher => publisher
    daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    fake_cybersource_form_path = "/fake/cybersource/path"

    load_confirm_page_for_cybersource_purchase(daily_deal_purchase)
    stub_cybersource_order_form_action(fake_cybersource_form_path)
    fill_out_cybersource_payment_form_with_invalid_postal_code
    click_buy_now
    ensure_still_on_purchase_confirmation_page(daily_deal_purchase)
    ensure_cybersource_postal_code_validation_error
    fix_postal_code
    click_buy_now
    ensure_cybersource_form_successfully_submitted(fake_cybersource_form_path)
  end

  test "braintree buy now form with invalid billing details, should mark required fields as invalid" do
    @publisher = Factory(:publisher, :production_daily_deal_host => "localhost:#{@port}")
    @deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher))

    # "Deal of the day" page
    visit "/publishers/#{@deal.publisher.label}/deal-of-the-day"
    assert page.has_css?("#buy_now_button"), "Should have 'Buy Now' button"
    click_link "buy_now_button"

    # "Review and Buy"
    fill_in_registration_form
    click_button "Review and Buy"

    click_button "Buy Now"
    assert_braintree_required_field_errors
  end

  test "braintree buy now form with invalid postal code" do
    @publisher = Factory(:publisher, :production_daily_deal_host => "localhost:#{@port}")
    @deal = Factory(:daily_deal, :advertiser => Factory(:advertiser, :publisher => @publisher))
    stubbed_consumer = Factory.stub(:consumer)

    # "Deal of the day" page
    visit "/publishers/#{@deal.publisher.label}/deal-of-the-day"
    assert page.has_css?("#buy_now_button"), "Should have 'Buy Now' button"
    click_link "buy_now_button"

    # "Review and Buy"
    fill_in_registration_fields(stubbed_consumer)
    click_button "Review and Buy"

    fill_in_payment_fields(stubbed_consumer)
    fill_in "Card Number *:", :with => "4005519200000004"
    fill_in "Billing ZIP Code *:", :with => "BLAH"
    click_button "Buy Now"

    ensure_braintree_postal_code_validation_error
  end

  test "review and buy now button becomes disabled after one click" do
    deal = Factory(:daily_deal)
    visit "/daily_deals/#{deal.id}/daily_deal_purchases/new"

    fill_in_registration_form

    assert page.has_css?("#review_button")
    assert page.has_not_css?("#review_button[disabled='disabled']")

    click_button "Review and Buy"

    # Here we have to check on the button in the "review and buy" page and not in the next buy page
    
    assert page.has_not_css?("review_button.disabled")
  end


  test "buy now button and reload the cybersource request" do
    entertainment = Factory :publishing_group, :label => "entertainment"
    publisher = Factory :publisher_using_cybersource, :publishing_group => entertainment
    deal = Factory :daily_deal, :publisher => publisher
    consumer = Factory :billing_address_consumer, :publisher => publisher
    daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal => deal, :consumer => consumer

    fake_cybersource_form_path = "/fake/cybersource/path"

    # Visit confirm page
    load_confirm_page_for_cybersource_purchase(daily_deal_purchase)
    stub_cybersource_order_form_action(fake_cybersource_form_path)

    # Buy
    fill_in_payment_form
    click_button "Buy Now"

    # Reload
    visit(current_path)

    ensure_cybersource_form_successfully_submitted(fake_cybersource_form_path)
  end

  private
  
  def create_purchase_for_publisher_within_group(publisher_label, publishing_group_label)
    publishing_group = Factory(:publishing_group, :label => publishing_group_label)
    publisher = Factory(:travelsavers_publisher, :label => publisher_label, :publishing_group => publishing_group)
    deal = Factory(:travelsavers_daily_deal, :publisher => publisher)
    Factory(:pending_daily_deal_purchase, :daily_deal => deal)
  end
  
  def assert_load_test_data_button_is_present_and_ts_checkout_form_validation_works(daily_deal_purchase)
    visit "/daily_deal_purchases/#{daily_deal_purchase.to_param}/confirm"

    assert_equal "Load Test Data", find("#load-fields")[:value]
    assert_equal Travelsavers::BookingRequest::URI, find("form#travelsavers_booking")[:action]

    # Change form action to prevent POST to TS server
    test_form_path = "/test/form/path"
    evaluate_script("jQuery(jQuery.find('form#travelsavers_booking')[0]).attr('action', '#{test_form_path}');")

    click_button "Buy Now"
    assert_travelsavers_required_field_errors

    fill_in_invalid_travelsavers_checkout_form
    click_button "Buy Now"
    assert_travelsavers_invalid_fields_errors

    assert_in_place_formatting_on_credit_card_expiration_date
    assert_in_place_formatting_on_birth_date

    assert_travelsavers_gender_title_validation
    assert_travelsavers_date_validation
    assert_travelsavers_credit_card_valid_date

    fill_in_valid_travelsavers_checkout_form
    click_button "Buy Now"
    assert_equal test_form_path, current_path # make sure browser actually POSTSs form (i.e. validation does not prevent it)
  end

  def load_confirm_page_for_cybersource_purchase(daily_deal_purchase)
    visit "/daily_deal_purchases/#{daily_deal_purchase.to_param}/confirm"
  end

  def stub_cybersource_order_form_action(stub_form_path)
    evaluate_script("jQuery(jQuery.find('form#new_cyber_source_order')[0]).attr('action', '#{stub_form_path}');")
  end
  
  def ensure_still_on_purchase_confirmation_page(daily_deal_purchase)
    assert_equal "/daily_deal_purchases/#{daily_deal_purchase.to_param}/confirm", current_path
  end

  def fill_out_cybersource_payment_form_with_invalid_zip_code
    fill_out_cybersource_non_postal_code_related_fields
    fill_in "Postal Code*", :with => "31"
    select "United States", :from => "Country*"
    select "OR", :with => "State/Province*"
  end

  def fill_out_cybersource_payment_form_with_invalid_postal_code
    fill_out_cybersource_non_postal_code_related_fields
    fill_in "Postal Code*", :with => "R22 3MM"
    select "Canada", :from => "Country*"
    select "MB", :with => "State/Province*"
  end

  def fill_out_cybersource_non_postal_code_related_fields
    fill_in "First Name*", :with => "Brad"
    fill_in "Last Name*", :with => "B"
    fill_in "Address Line 1*", :with => "100 Test Road"
    fill_in "City*", :with => "Portland"
    select "Visa", :from => "Card Type*"
    fill_in "Card Number*", :with => "4111111111111111"
    select "12", :from => "cyber_source_order_card_expiration_month"
    select "2020", :from => "cyber_source_order_card_expiration_year"
    fill_in "CVV*", :with => "111"
  end

  def click_buy_now
    click_button "Buy Now"
  end

  def ensure_cybersource_postal_code_validation_error
    assert page.has_css? "label[for=cyber_source_order_billing_postal_code]", :text => "Please enter a valid postal code."
  end

  def ensure_braintree_postal_code_validation_error
    assert page.has_css? "input[name='transaction[billing][postal_code]'][type='text'][class='autowidth required zipCode invalid']"
  end

  def fix_zip_code
    fill_in "Postal Code*", :with => "90210"
  end

  def fix_postal_code
    fill_in "Postal Code*", :with => "R2M 3W7"
  end

  def ensure_cybersource_form_successfully_submitted(expected_path)
    assert_equal expected_path, current_path
  end

  def fill_in_registration_form
    fill_in "Your Name:", :with => "John Doe"
    fill_in "Email:", :with => "jdoe@analoganalytics.com"
    fill_in "Password:", :with => "password"
    fill_in "Confirm Password:", :with => "password"
    check "I agree to the Terms and Privacy Policy"
  end

  def fill_in_payment_form
    fill_in "Cardholder Name *:", :with => Faker::Name.name
    fill_in "Card Number *:", :with => "4111111111111111"
    fill_in "CVV *:", :with => "123"
    fill_in "Billing Address Line 1 *", :with => Faker::Address.street_address
    fill_in "Billing Address City *", :with => Faker::Address.city
    fill_in "Billing ZIP Code *:", :with => Faker::Address.zip_code
  end

  def assert_thank_you_page
    assert page.has_content?("Thank You")
    assert page.has_link?("View your orders")
  end

  def fill_in_mailing_address
    within_fieldset("Mailing Address") do
      fill_in "Address 1", :with => "123 Maple Ave"
      fill_in "Address 2", :with => "Unit B"
      fill_in "City", :with => "Beaverton"
      select "OR", :from => "State"
      fill_in "Zip", :with => "97005"
    end
  end

  def assert_braintree_required_field_errors
    assert page.has_css? "input[name='transaction[credit_card][cardholder_name]'][type='text'][class='required invalid']"
    assert page.has_css? "input[name='transaction[credit_card][number]'][type='text'][class='required invalid']"
    assert page.has_css? "input[name='transaction[credit_card][cvv]'][type='text'][class='autowidth required invalid']"
    assert page.has_css? "input[name='transaction[billing][street_address]'][type='text'][class='required invalid']"
    assert page.has_no_css? "input[name='transaction[billing][extended_address]'][type='text'][class='invalid']"
    assert page.has_css? "input[name='transaction[billing][locality]'][type='text'][class='required invalid']"
    ensure_braintree_postal_code_validation_error
  end

  def assert_travelsavers_required_field_errors
    required_text = "This field is required"
    assert page.has_css? "label[for=credit_card_cardholder_firstname].error", :text => required_text
    assert page.has_css? "label[for=credit_card_cardholder_lastname].error", :text => required_text
    assert page.has_css? "label[for=credit_card_vendor_code].error", :text => required_text
    assert page.has_css? "label[for=credit_card_number].error", :text => required_text
    assert page.has_css? "label[for=credit_card_cvv].error", :text => required_text
    assert page.has_css? "label[for=credit_card_expiration_date].error", :text => required_text
    assert page.has_css? "label[for=credit_card_billing_address_line_1].error", :text => required_text
    assert page.has_css? "label[for=credit_card_billing_locality].error", :text => required_text
    assert page.has_css? "label[for=credit_card_billing_region].error", :text => required_text
    assert page.has_css? "label[for=credit_card_billing_postal_code].error", :text => required_text
    2.times do |i|
      assert page.has_css? "label[for=traveler_#{i}_birth_date].error", :text => required_text
      assert page.has_css? "label[for=traveler_#{i}_citizenship].error", :text => required_text
      assert page.has_css? "label[for=traveler_#{i}_phone_number].error", :text => required_text
      assert page.has_css? "label[for=traveler_#{i}_email].error", :text => required_text
      assert page.has_css? "label[for=traveler_#{i}_address_line_1].error", :text => required_text
      assert page.has_css? "label[for=traveler_#{i}_locality].error", :text => required_text
      assert page.has_css? "label[for=traveler_#{i}_region].error", :text => required_text
      assert page.has_css? "label[for=traveler_#{i}_postal_code].error", :text => required_text
    end
  end

  def fill_in_invalid_travelsavers_checkout_form
    fill_in "credit_card_number", :with => "1234123412341234"
    fill_in "credit_card_cvv", :with => "12435"
    fill_in "credit_card_expiration_date", :with => "0613"
    fill_in "credit_card_billing_postal_code", :with => "9700"
    (0..1).each do |i|
      fill_in "traveler_#{i}_birth_date", :with => "120877"
      fill_in "traveler_#{i}_citizenship", :with => "CAN"
      fill_in "traveler_#{i}_phone_number", :with => "503-321-123"
      fill_in "traveler_#{i}_email", :with => "john.smith#domain.com"
      fill_in "traveler_#{i}_postal_code", :with => "97005-123"
    end
  end

  def assert_travelsavers_invalid_fields_errors
    assert page.has_css? "label[for=credit_card_number].error", :text => "Please enter a valid credit card number."
    assert page.has_css? "label[for=credit_card_cvv].error", :text => "Please enter a valid security code (3-4 digits)."
    assert page.has_css? "label[for=credit_card_expiration_date].error", :text => "Please enter the expiration date in the following format mm/yyyyy"
    assert page.has_css? "label[for=credit_card_billing_postal_code].error", :text => "Please enter a valid US zip code."
    (0..1).each do |i|
      assert page.has_css? "label[for=traveler_#{i}_birth_date].error", :text => "Please enter a complete date of birth."
      assert page.has_css? "label[for=traveler_#{i}_citizenship].error", :text => "Please enter a 2-letter country code."
      assert page.has_css? "label[for=traveler_#{i}_phone_number].error", :text => "Please specify a valid phone number"
      assert page.has_css? "label[for=traveler_#{i}_email].error", :text => "Please enter a valid email address."
      assert page.has_css? "label[for=traveler_#{i}_postal_code].error", :text => "Please enter a valid US zip code."
    end
  end

  def fill_in_valid_travelsavers_checkout_form
    fill_in "credit_card_cardholder_firstname", :with => "John"
    fill_in "credit_card_cardholder_lastname", :with => "Smith"
    select "MasterCard", :from => "credit_card_vendor_code"
    fill_in "credit_card_number", :with => "4111111111111111"
    fill_in "credit_card_cvv", :with => "123"
    fill_in "credit_card_expiration_date", :with => "062013"
    fill_in "credit_card_billing_address_line_1", :with => "123 Maple Ave"
    fill_in "credit_card_billing_locality", :with => "Beaverton"
    select "Oregon", :from => "credit_card_billing_region"
    fill_in "credit_card_billing_postal_code", :with => "97005"
    2.times do |i|
      select "Mr", :from => "traveler_#{i}_title"
      fill_in "traveler_#{i}_first_name", :with => "John"
      fill_in "traveler_#{i}_last_name", :with => "Smith"
      select "M", :from => "traveler_#{i}_gender"
      fill_in "traveler_#{i}_birth_date", :with => "12081977"
      fill_in "traveler_#{i}_citizenship", :with => "CA"
      fill_in "traveler_#{i}_phone_number", :with => "503-321-1234"
      fill_in "traveler_#{i}_email", :with => "john.smith@domain.com"
      fill_in "traveler_#{i}_address_line_1", :with => "123 Maple Ave"
      fill_in "traveler_#{i}_locality", :with => "Beaverton"
      select "Oregon", :from => "traveler_#{i}_region"
      fill_in "traveler_#{i}_postal_code", :with => "97005"
      check "traveler_#{i}_terms_accepted"
    end
  end

  def assert_travelsavers_gender_title_validation
    (0..1).each do |i|
      [["Mr", "Female"], ["Mrs", "Male"]].each do |title, gender|
        assert_gender_validation_when_title_selected_before_gender(title, gender, i)
        assert_gender_validation_when_gender_selected_before_title(title, gender, i)
      end
    end
  end

  def invalidate_title_and_gender(gender, i, title)
    select title, :from => "traveler_#{i}_title"
    select gender, :from => "traveler_#{i}_gender"
  end

  def assert_gender_error(i)
    assert page.has_css? "label[for=traveler_#{i}_gender].error", :text => "Please select a valid gender for the selected title."
  end

  def valid_title(gender)
    gender == "Male" ? "Mr" : "Mrs"
  end

  def valid_gender(title)
    title == "Mr" ? "Male" : "Female"
  end

  def assert_no_gender_error(i)
    assert !find("label[for=traveler_#{i}_gender].error").visible?
  end

  def assert_gender_validation_when_title_selected_before_gender(title, gender, i)
    clear_title_and_gender(i)
    select title, :from => "traveler_#{i}_title"
    select invalid_gender(title), :from => "traveler_#{i}_gender"
    assert_gender_error(i)
    select valid_title(gender), :from => "traveler_#{i}_title"
    assert_no_gender_error(i)
  end

  def assert_gender_validation_when_gender_selected_before_title(title, gender, i)
    clear_title_and_gender(i)
    select "", :from => "traveler_#{i}_title"
    select gender, :from => "traveler_#{i}_gender"
    select invalid_title(gender), :from => "traveler_#{i}_title"
    assert_gender_error(i)
    select valid_title(gender), :from => "traveler_#{i}_title"
    assert_no_gender_error(i)
  end

  def invalid_gender(title)
    %w(Mr Mstr).include?(title) ? "Female" : "Male"
  end

  def invalid_title(gender)
    gender == "Male" ? "Mrs" : "Mr"
  end

  def clear_title_and_gender(i)
    select "", :from => "traveler_#{i}_title"
    select "", :from => "traveler_#{i}_gender"
  end

  def assert_travelsavers_date_validation
    (0..1).each do |i|
      assert_date_validation_when_day_does_not_match_month(i)
      assert_date_validation_on_leap_year(i)
      assert_date_validation_when_year_is_out_of_range(i)
    end
  end

  def assert_date_validation_when_day_does_not_match_month(i)
    fill_in "traveler_#{i}_birth_date", :with => "02311990"
    assert page.has_css? "label[for=traveler_#{i}_birth_date].error", :text => "Please enter a valid date."
    fill_in "traveler_#{i}_birth_date", :with => "12081977"
    assert !find("label[for=traveler_#{i}_birth_date].error").visible?
  end

  def assert_date_validation_on_leap_year(i)
    fill_in "traveler_#{i}_birth_date", :with => "02292011"
    assert page.has_css? "label[for=traveler_#{i}_birth_date].error", :text => "Please enter a valid date."
    fill_in "traveler_#{i}_birth_date", :with => "02292012"
    assert !find("label[for=traveler_#{i}_birth_date].error").visible?
  end

  def assert_date_validation_when_year_is_out_of_range(i)
    fill_in "traveler_#{i}_birth_date", :with => "02311776"
    assert page.has_css? "label[for=traveler_#{i}_birth_date].error", :text => "Please enter a valid date."
    fill_in "traveler_#{i}_birth_date", :with => "12081977"
    assert !find("label[for=traveler_#{i}_birth_date].error").visible?
  end

  def assert_travelsavers_credit_card_valid_date
    assert_credit_card_valid_on_date("022012")
    assert_credit_card_valid_on_date("13#{Time.zone.now.year + 1}")
    assert_credit_card_valid_on_date("151900")

    fill_in "credit_card_expiration_date", :with => "#{Time.zone.now.month.to_s.rjust(2,"0")}#{Time.zone.now.year}"
    assert !find("label[for=credit_card_expiration_date].error").visible?
  end

  def assert_credit_card_valid_on_date(date)
    fill_in "credit_card_expiration_date", :with => date
    assert page.has_css? "label[for=credit_card_expiration_date].error", :text => "Please use an active card."
    fill_in "credit_card_expiration_date", :with => "02#{Time.zone.now.year + 1}"
    assert !find("label[for=credit_card_expiration_date].error").visible?
  end

  def assert_auto_format_of_credit_card_expiration
    fill_in "credit_card_expiration_date", :with => "12#{Time.zone.now.year + 1}"
    assert !find("label[for=credit_card_expiration_date].error").visible?
  end

  def assert_in_place_formatting_on_credit_card_expiration_date
    fill_in "credit_card_expiration_date", :with => "01"
    wait_until { find_field("credit_card_expiration_date").value == "01/" }
  end

  def assert_in_place_formatting_on_birth_date
    [0,1].each do |i|
      fill_in "traveler_#{i}_birth_date", :with => "01"
      wait_until { find_field("traveler_#{i}_birth_date").value == "01/" }
      fill_in "traveler_#{i}_birth_date", :with => "0212"
      wait_until { find_field("traveler_#{i}_birth_date").value == "02/12/" }
    end
  end
end

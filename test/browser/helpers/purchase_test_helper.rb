module PurchaseTestHelper

  # For multiple purchases to avoid BrainTree duplicate gateway rejects
  CREDIT_CARD_NUMBERS = [4111111111111111, 4005519200000004, 4009348888881881, 4012000033330026]

  def fill_in_registration_fields(consumer)
    fill_in "consumer_name", :with => consumer.name
    fill_in "consumer_email", :with => consumer.email
    fill_in "consumer_password", :with => consumer.password
    fill_in "consumer_password_confirmation", :with => consumer.password
    check "I agree to the Terms and Privacy Policy"
  end

  def fill_in_payment_fields(consumer, card_only = false)
    credit_card_number = CREDIT_CARD_NUMBERS.delete_at(0)
    CREDIT_CARD_NUMBERS.push(credit_card_number)
    fill_in "transaction_credit_card_cardholder_name", :with => consumer.name
    fill_in "transaction_credit_card_number", :with => credit_card_number
    fill_in "transaction_credit_card_cvv", :with => "123"
    unless card_only
      fill_in "transaction_billing_street_address", :with => "123 Maple Ave"
      fill_in "transaction_billing_locality", :with => "Portland"
      select "OR", :from => "transaction_billing_region"
      fill_in "transaction_billing_postal_code", :with => "97005"
      select "United States", :from => "transaction_billing_country_code_alpha2"
    end
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

  def fill_in_shipping_fields
    fill_in "daily_deal_purchase_recipients_attributes_0_name", :with => "John Doe"
    fill_in "daily_deal_purchase_recipients_attributes_0_address_line_1", :with => "123 Maple Ave"
    fill_in "daily_deal_purchase_recipients_attributes_0_address_line_2", :with => "Unit B"
    fill_in "daily_deal_purchase_recipients_attributes_0_city", :with => "Beaverton"
    select "OR", :from => "daily_deal_purchase_recipients_attributes_0_state"
    fill_in "daily_deal_purchase_recipients_attributes_0_zip", :with => "97005"
  end

  def fill_in_sign_in_fields(consumer)
    fill_in "session_email", :with => consumer.email
    fill_in "session_password", :with => consumer.password
  end

  def wait_until_visible(locator, seconds = 10)
    raise ArgumentError if locator.blank?

    begin
      Timeout::timeout(seconds) do
        until page.has_css?(locator) && find(locator).visible?
          sleep 0.25
        end
      end
    rescue Timeout::Error => e
      fail "'#{locator}' did not appear within #{seconds} seconds"
    end
  end

end
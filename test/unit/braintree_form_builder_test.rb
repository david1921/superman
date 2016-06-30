require File.dirname(__FILE__) + "/../test_helper"

class BraintreeFormBuilderTest < ActiveSupport::TestCase
  
  context "with no braintree result" do
    
    setup do
      @context      = ActionView::Base.new
      @builder      = BraintreeFormBuilder.new(:transaction, nil, @context, {}, nil)
    end
    
    should "display no error messages" do
      assert @builder.display_braintree_error_messages.blank?
    end
    
      
    should "render default credit card fields" do
      @builder.fields_for(:credit_card) do |c|
        assert_equal c.text_field_div(:cardholder_name), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_cardholder_name\">Cardholder Name:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_credit_card_cardholder_name\" name=\"transaction[credit_card][cardholder_name]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
        assert_equal c.text_field_div(:number), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_number\">Number:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_credit_card_number\" name=\"transaction[credit_card][number]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
        assert_equal c.expiration_date_div("Expiration Date", {:month_options => "<option value=\"01\">01</option>", :year_options => "<option value=\"2011\">2011</option>"}), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_\">Expiration Date:</label></div>\n  <div class=\"expiration_date\">\n    <select id=\"transaction_credit_card_expiration_month\" name=\"transaction[credit_card][expiration_month]\"><option value=\"01\">01</option></select>\n    <select id=\"transaction_credit_card_expiration_year\" name=\"transaction[credit_card][expiration_year]\"><option value=\"2011\">2011</option></select>\n  </div>\n</div>"
        assert_equal c.cvv_div("CVV"), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_cvv\">CVV *:</label></div>\n  <div class=\"input\">\n    <div class=\"transaction_credit_card_cvv\" style=\"text-align: left\">\n      <div class=\"\"><input class=\"autowidth required\" id=\"transaction_credit_card_cvv\" name=\"transaction[credit_card][cvv]\" size=\"4\" type=\"text\" /></div>\n      <a id=\"what-is-cvv\" href=\"/en/what-is-cvv\" onclick=\"window.open('/en/what-is-cvv', '', 'width=560,height=315,left=200,top=200,status=no,toolbar=no,location=no,menubar=no,titlebar=no'); return false\">What's this?</a>\n    </div>\n  </div>\n  <div class=\"help\"></div>\n</div>"
      end
    end
    
    should "render default billing fields" do
      @builder.fields_for(:billing) do |b|
        assert_equal b.text_field_div(:postal_code), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_billing_postal_code\">Postal Code:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_billing_postal_code\" name=\"transaction[billing][postal_code]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
      end
    end
                    
  end
  
  context "with braintree result" do
    
    setup do
      @result       = mock("braintree-result")
      @context      = ActionView::Base.new
      @builder      = BraintreeFormBuilder.new(:transaction, nil, @context, {:result => @result}, nil)
    end
    
    context "with no error messages or basic message" do
      
      setup do
        @result.stubs(:errors).returns([])
        @result.stubs(:message).returns("")
        @result.stubs(:params).returns({})
      end
      
      should "display no error messages" do
        assert @builder.display_braintree_error_messages.blank?
      end


      should "render default credit card fields" do
        @builder.fields_for(:credit_card) do |c|
          assert_equal c.text_field_div(:cardholder_name), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_cardholder_name\">Cardholder Name:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_credit_card_cardholder_name\" name=\"transaction[credit_card][cardholder_name]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
          assert_equal c.text_field_div(:number), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_number\">Number:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_credit_card_number\" name=\"transaction[credit_card][number]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
          assert_equal c.expiration_date_div("Expiration Date", {:month_options => "<option value=\"01\">01</option>", :year_options => "<option value=\"2011\">2011</option>"}), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_\">Expiration Date:</label></div>\n  <div class=\"expiration_date\">\n    <select id=\"transaction_credit_card_expiration_month\" name=\"transaction[credit_card][expiration_month]\"><option value=\"01\">01</option></select>\n    <select id=\"transaction_credit_card_expiration_year\" name=\"transaction[credit_card][expiration_year]\"><option value=\"2011\">2011</option></select>\n  </div>\n</div>"
          assert_equal c.cvv_div("CVV"), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_cvv\">CVV *:</label></div>\n  <div class=\"input\">\n    <div class=\"transaction_credit_card_cvv\" style=\"text-align: left\">\n      <div class=\"\"><input class=\"autowidth required\" id=\"transaction_credit_card_cvv\" name=\"transaction[credit_card][cvv]\" size=\"4\" type=\"text\" /></div>\n      <a id=\"what-is-cvv\" href=\"/en/what-is-cvv\" onclick=\"window.open('/en/what-is-cvv', '', 'width=560,height=315,left=200,top=200,status=no,toolbar=no,location=no,menubar=no,titlebar=no'); return false\">What's this?</a>\n    </div>\n  </div>\n  <div class=\"help\"></div>\n</div>"
        end
      end

      should "render default billing fields" do
        @builder.fields_for(:billing) do |b|
          assert_equal b.text_field_div(:postal_code), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_billing_postal_code\">Postal Code:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_billing_postal_code\" name=\"transaction[billing][postal_code]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
        end
      end      
      
      
    end
    
    context "with no error messages but with a basic message" do
      
      setup do
        @result.stubs(:errors).returns([])
        @result.stubs(:message).returns("Insufficient funds.")
        @result.stubs(:params).returns({})
      end
      
      should "display error message" do
        assert_equal @builder.display_braintree_error_messages, "\n<div class=\"daily_deal_purchase_errors\">\n  <h3>#{I18n.t("daily_deal_purchases.braintree_buy_now_form.payment_error_message_header")}</h3>\n  <ul><li>Insufficient funds.</li></ul>\n</div>\n    "
      end
      
      should "render default credit card fields" do
        @builder.fields_for(:credit_card) do |c|
          assert_equal c.text_field_div(:cardholder_name), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_cardholder_name\">Cardholder Name:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_credit_card_cardholder_name\" name=\"transaction[credit_card][cardholder_name]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
          assert_equal c.text_field_div(:number), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_number\">Number:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_credit_card_number\" name=\"transaction[credit_card][number]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
          assert_equal c.expiration_date_div("Expiration Date", {:month_options => "<option value=\"01\">01</option>", :year_options => "<option value=\"2011\">2011</option>"}), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_\">Expiration Date:</label></div>\n  <div class=\"expiration_date\">\n    <select id=\"transaction_credit_card_expiration_month\" name=\"transaction[credit_card][expiration_month]\"><option value=\"01\">01</option></select>\n    <select id=\"transaction_credit_card_expiration_year\" name=\"transaction[credit_card][expiration_year]\"><option value=\"2011\">2011</option></select>\n  </div>\n</div>"
          assert_equal c.cvv_div("CVV"), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_cvv\">CVV *:</label></div>\n  <div class=\"input\">\n    <div class=\"transaction_credit_card_cvv\" style=\"text-align: left\">\n      <div class=\"\"><input class=\"autowidth required\" id=\"transaction_credit_card_cvv\" name=\"transaction[credit_card][cvv]\" size=\"4\" type=\"text\" /></div>\n      <a id=\"what-is-cvv\" href=\"/en/what-is-cvv\" onclick=\"window.open('/en/what-is-cvv', '', 'width=560,height=315,left=200,top=200,status=no,toolbar=no,location=no,menubar=no,titlebar=no'); return false\">What's this?</a>\n    </div>\n  </div>\n  <div class=\"help\"></div>\n</div>"
        end
      end

      should "render default billing fields" do
        @builder.fields_for(:billing) do |b|
          assert_equal b.text_field_div(:postal_code), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_billing_postal_code\">Postal Code:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_billing_postal_code\" name=\"transaction[billing][postal_code]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
        end
      end
      
    end
    
    context "with error messages but no basic message" do
      
      setup do
        @error = OpenStruct.new(:attribute => "number", :message => "Card Number is missing.")
        @result.stubs(:errors).returns([@error])
        @result.stubs(:message).returns("")
        @result.stubs(:params).returns({})
      end

      should "display error message" do
        assert_equal @builder.display_braintree_error_messages, "\n<div class=\"daily_deal_purchase_errors\">\n  <h3>#{I18n.t("daily_deal_purchases.braintree_buy_now_form.payment_error_message_header")}</h3>\n  <ul><li>#{@error.message}</li></ul>\n</div>\n    "
      end
      
      should "render default credit card fields for cardholder_name, expiration date, and cvv and an error field for number" do
        @builder.fields_for(:credit_card) do |c|
          assert_equal c.text_field_div(:cardholder_name), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_cardholder_name\">Cardholder Name:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_credit_card_cardholder_name\" name=\"transaction[credit_card][cardholder_name]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
          assert_equal c.text_field_div(:number), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_number\">Number:</label></div>\n  <div class=\"input\"><div class=\"fieldWithErrors\"><input id=\"transaction_credit_card_number\" name=\"transaction[credit_card][number]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
          assert_equal c.expiration_date_div("Expiration Date", {:month_options => "<option value=\"01\">01</option>", :year_options => "<option value=\"2011\">2011</option>"}), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_\">Expiration Date:</label></div>\n  <div class=\"expiration_date\">\n    <select id=\"transaction_credit_card_expiration_month\" name=\"transaction[credit_card][expiration_month]\"><option value=\"01\">01</option></select>\n    <select id=\"transaction_credit_card_expiration_year\" name=\"transaction[credit_card][expiration_year]\"><option value=\"2011\">2011</option></select>\n  </div>\n</div>"
          assert_equal c.cvv_div("CVV"), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_credit_card_cvv\">CVV *:</label></div>\n  <div class=\"input\">\n    <div class=\"transaction_credit_card_cvv\" style=\"text-align: left\">\n      <div class=\"\"><input class=\"autowidth required\" id=\"transaction_credit_card_cvv\" name=\"transaction[credit_card][cvv]\" size=\"4\" type=\"text\" /></div>\n      <a id=\"what-is-cvv\" href=\"/en/what-is-cvv\" onclick=\"window.open('/en/what-is-cvv', '', 'width=560,height=315,left=200,top=200,status=no,toolbar=no,location=no,menubar=no,titlebar=no'); return false\">What's this?</a>\n    </div>\n  </div>\n  <div class=\"help\"></div>\n</div>"
        end
      end

      should "render default billing fields" do
        @builder.fields_for(:billing) do |b|
          assert_equal b.text_field_div(:postal_code), "\n<div class=\"row\">\n  <div class=\"label\"><label for=\"transaction_billing_postal_code\">Postal Code:</label></div>\n  <div class=\"input\"><div class=\"\"><input id=\"transaction_billing_postal_code\" name=\"transaction[billing][postal_code]\" size=\"30\" type=\"text\" /></div></div>\n  <div class=\"help\"></div>\n</div>"
        end
      end
      
    end
    
  end

end
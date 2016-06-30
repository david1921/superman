require File.dirname(__FILE__) + "/../../models_helper"

class DailyDealPurchases::CyberSourceTest < Test::Unit::TestCase
  def setup
    @purchase = Object.new.extend(DailyDealPurchases::CyberSource::InstanceMethods)
  end

  context "#cyber_source_execute!" do
    setup do
      @order = stub("cybersource order",
                    :request_id => "request id",
                    :reconciliation_id => nil,
                    :authorized_at => "authorized at",
                    :amount => nil,
                    :card_last_4 => nil,
                    :billing_postal_code => nil,
                    :decision => nil,
                    :billing_first_name => "John",
                    :billing_last_name => "Public",
                    :billing_address_line_1 => "123 Main Street",
                    :billing_address_line_2 => "Apartment 4",
                    :billing_city => "Portland",
                    :billing_state => "OR",
                    :billing_country => "US",
                    :billing_postal_code => "97005",
                    :credit_card_bin => "411111",
                    :card_last_4 => "1111"
      )
      @payment = mock("payment")
      @purchase.stubs(:daily_deal_payment => nil, :create_cyber_source_payment! => @payment)
      @purchase.stubs(:daily_deal_payment=).returns(@payment)
      @purchase.expects(:executed_at=).with("authorized at")
      @purchase.expects(:payment_status_updated_by_txn_id=).with("request id")
      @purchase.expects(:set_payment_status!).with("captured")
    end

    should "set the cardholder name" do
      @purchase.expects(:create_cyber_source_payment!).with(has_entry(:name_on_card, "John Public"))
      @purchase.send(:cyber_source_execute!, @order)
    end

    should "set the billing address line 1" do
      @purchase.expects(:create_cyber_source_payment!).with(has_entry(:billing_address_line_1, "123 Main Street"))
      @purchase.send(:cyber_source_execute!, @order)
    end

    should "set the billing address line 2" do
      @purchase.expects(:create_cyber_source_payment!).with(has_entry(:billing_address_line_2, "Apartment 4"))
      @purchase.send(:cyber_source_execute!, @order)
    end

    should "set the billing address city" do
      @purchase.expects(:create_cyber_source_payment!).with(has_entry(:billing_city, "Portland"))
      @purchase.send(:cyber_source_execute!, @order)
    end

    should "set the billing address state" do
      @purchase.expects(:create_cyber_source_payment!).with(has_entry(:billing_state, "OR"))
      @purchase.send(:cyber_source_execute!, @order)
    end

    should "set the billing country" do
      @purchase.expects(:create_cyber_source_payment!).with(has_entry(:billing_country_code, "US"))
      @purchase.send(:cyber_source_execute!, @order)
    end

    should "set the billing address postal code" do
      @purchase.expects(:create_cyber_source_payment!).with(has_entry(:payer_postal_code, "97005"))
      @purchase.send(:cyber_source_execute!, @order)
    end

    should "set the credit card BIN" do
      @purchase.expects(:create_cyber_source_payment!).with(has_entry(:credit_card_bin, "411111"))
      @purchase.send(:cyber_source_execute!, @order)
    end

    should "set the card number last 4" do
      @purchase.expects(:create_cyber_source_payment!).with(has_entry(:credit_card_last_4, "1111"))
      @purchase.send(:cyber_source_execute!, @order)
    end

  end
end

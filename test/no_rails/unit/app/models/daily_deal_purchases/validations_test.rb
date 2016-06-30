require File.dirname(__FILE__) + "/../../models_helper"

class DailyDealPurchases::ValidationsTest < Test::Unit::TestCase
  def setup
    errors = stub(:add_to_base => nil)
    @purchase = stub('Purchase', :errors => errors, :certificates_to_generate_per_unit_quantity => 1)
    @purchase.extend(DailyDealPurchases::Core)
    @purchase.extend(DailyDealPurchases::Validations)
  end

  context "#recipient_names_match_quantity_times_voucher_multiple" do
    context "gift purchase" do
      setup do
        @purchase.stubs(:gift? => true, :quantity => 3, :certificates_to_generate_per_unit_quantity => 1)
        @error = I18n.t("activerecord.errors.custom.should_be_multiple_recipient", :quantity => 3)
      end

      should "require some recipients" do
        @purchase.stubs(:recipient_names => nil)
        @purchase.errors.expects(:add_to_base).with(@error)
        @purchase.recipient_names_match_quantity_times_voucher_multiple
      end

      should "require number of recipient to match the purchase quantity" do
        @purchase.stubs(:recipient_names => stub(:size => @purchase.quantity - 1))
        @purchase.errors.expects(:add_to_base).with(@error)
        @purchase.recipient_names_match_quantity_times_voucher_multiple
      end

      should "require non-blank recipient names" do
        @purchase.stubs(:recipient_names => ['', 'John', 'Scott'])
        @purchase.errors.expects(:add_to_base).with(@error)
        @purchase.recipient_names_match_quantity_times_voucher_multiple
      end
    end

    context "non-gift purchase" do
      should "not set an error" do
        @purchase.stubs(:gift? => false)
        @purchase.expects(:errors).never
        @purchase.recipient_names_match_quantity_times_voucher_multiple
      end
    end
  end

  context "#recipients_match_quantity_times_voucher_multiple" do
    should "not set an error if the shipping address is not required" do
      deal = stub(:requires_shipping_address? => false)
      @purchase.stubs(:daily_deal).returns(deal)
      @purchase.expects(:errors).never
      @purchase.recipients_match_quantity_times_voucher_multiple
    end

    context "shipping address required" do
      setup do
        deal = stub(:requires_shipping_address? => true)
        @purchase.stubs(:daily_deal).returns(deal)
        @purchase.stubs(:recipients).returns(['John', 'Adam'])
      end

      should "require number of recipient to match the purchase quantity for a gift purchase" do
        @purchase.stubs(:gift? => true)
        @purchase.stubs(:quantity).returns(3)
        error = I18n.t("activerecord.errors.custom.should_be_multiple_recipient", :quantity => 3)
        @purchase.errors.expects(:add).with(:recipients, error)
        @purchase.recipients_match_quantity_times_voucher_multiple
      end

      should "require 1 recipient when not a gift purchase" do
        @purchase.stubs(:gift? => false)
        error = I18n.t("activerecord.errors.custom.should_be_one_recipient") 
        @purchase.errors.expects(:add).with(:recipients, error)
        @purchase.recipients_match_quantity_times_voucher_multiple
      end
    end
  end

end

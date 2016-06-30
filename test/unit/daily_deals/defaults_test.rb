require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::DefaultsTest < ActiveSupport::TestCase
  context "#assign_defaults" do
      should "assign_initial_voucher_steps" do
        deal = DailyDeal.new
        deal.expects(:assign_initial_voucher_steps).once
        deal.assign_defaults
      end

      should "assign_initial_email_voucher_redemption_message" do
        deal = DailyDeal.new
        deal.expects(:assign_initial_email_voucher_redemption_message).once
        deal.assign_defaults
      end
  end

  context "assign_initial_voucher_steps" do
    should "set voucher_steps to the default when empty and publisher is known" do
      advertiser = Factory(:advertiser)
      publisher = advertiser.publisher
      deal = DailyDeal.new(:advertiser => advertiser, :publisher => publisher)
      deal.assign_initial_voucher_steps
      assert_equal deal.voucher_steps, publisher.default_voucher_steps(advertiser.name)
    end

    # TODO: do we really want voucher_steps to be a blank string or can we get
    # voucher_steps from another source? advertiser?
    should "set voucher_steps to empty string when empty and publisher not known" do
      advertiser = Factory(:advertiser)
      deal = DailyDeal.new(:advertiser => advertiser)
      deal.assign_initial_voucher_steps
      assert_equal "", deal.voucher_steps
    end
  end

  context "assign_initial_email_voucher_redemption_message" do
    should "set email_voucher_redemption_message to the default when empty" do
      advertiser = Factory(:advertiser)
      deal = DailyDeal.new(:advertiser => advertiser)
      deal.assign_initial_email_voucher_redemption_message
      assert_equal deal.email_voucher_redemption_message, DailyDeal.default_email_voucher_redemption_message(advertiser)
    end
  end

  context "maximum quantity" do
    should "use default" do
      deal = Factory(:daily_deal)
      assert_equal 10, deal.max_quantity, "max_quantity"
    end

    should "use publishing group default" do
      publishing_group = Factory(:publishing_group, :max_quantity_default => 5)
      publisher = Factory(:publisher, :publishing_group => publishing_group)
      advertiser = Factory(:advertiser, :publisher => publisher)
      deal = Factory(:daily_deal, :advertiser => advertiser, :publisher => publisher)
      assert_equal 5, deal.max_quantity, "max_quantity"
    end
  end

  # Terms are handled differently because they are a translated text field. 
  # There may be a way to handle it all in the model and not the controller, but it's subtle if it exists.
  context "terms" do
    should "default" do
      publishing_group = Factory(:publishing_group, :max_quantity_default => 5)
      publisher = Factory(:publisher, :publishing_group => publishing_group)
      advertiser = Factory(:advertiser, :publisher => publisher)
      deal = DailyDeal.new(:advertiser => advertiser, :publisher => publisher)
      assert_equal "", publisher.default_terms, "default_terms"
      assert_equal nil, deal.terms, "terms"
    end

    should "ignore publishing group default" do
      publishing_group = Factory(:publishing_group, :terms_default => " * Only in Vermont")
      publisher = Factory(:publisher, :publishing_group => publishing_group)
      advertiser = Factory(:advertiser, :publisher => publisher)
      attributes = Factory.attributes_for(:daily_deal).merge(:advertiser => advertiser, :publisher => publisher)
      attributes.delete(:terms)
      deal = DailyDeal.new(attributes)
      assert_equal " * Only in Vermont", publisher.default_terms, "default_terms"
      assert_equal nil, deal.terms, "terms"
    end

    should "override publishing group default" do
      publishing_group = Factory(:publishing_group, :terms_default => " * Only in Vermont")
      publisher = Factory(:publisher, :publishing_group => publishing_group)
      advertiser = Factory(:advertiser, :publisher => publisher)
      deal = Factory(:daily_deal, :advertiser => advertiser, :publisher => publisher)
      assert_equal " * Only in Vermont", publisher.default_terms, "default_terms"
      assert_equal "<p>these are my terms</p>", deal.terms, "terms"
    end
  end

end

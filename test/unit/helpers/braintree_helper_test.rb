require File.dirname(__FILE__) + "/../../test_helper"

class BraintreeHelperTest < ActionView::TestCase
  test "braintree_merchant_account_attrs for publisher without publishing group" do
    publisher = Factory(:publisher, :label => "8newsnow", :merchant_account_id => "8NewsNow")
    assert_equal({ :merchant_account_id => "8NewsNow" }, braintree_merchant_account_attrs(publisher))
  end

  test "braintree_merchant_account_attrs for publishing group and not publisher" do
    publisher = Factory(:publisher, :label => "laweekly", 
                        :publishing_group => Factory(:publishing_group, :label => "villagevoicemedia", :merchant_account_id => "VillageVoice"))
    assert_equal({ :merchant_account_id => "VillageVoice" }, braintree_merchant_account_attrs(publisher))
  end

  test "braintree_merchant_account_attrs for publisher and no publishing group no merchant id set" do
    publisher = Factory(:publisher, :label => "xxxxxxxx")
    assert_equal({}, braintree_merchant_account_attrs(publisher))
  end

  test "braintree_merchant_account_attrs with publishing group but no merchant id set" do
    publisher = Factory(:publisher, :label => "xxxxxxxx", :publishing_group => Factory(:publishing_group, :label => "xxxxxxxxxxxxxxxxx"))
    assert_equal({}, braintree_merchant_account_attrs(publisher))
  end

  context "#braintree_custom_field_attrs" do
    setup do
      @publisher = Factory(:publisher, :merchant_account_id => "TestMID")
      @daily_deal = Factory(:daily_deal)
    end

    context "default" do
      should "return the MID and daily deal id" do
        fields = { :custom_fields => {
          :litle_report_group => "TestMID",
          :litle_campaign => @daily_deal.id }}

        assert_equal fields, braintree_custom_field_attrs(@daily_deal.id, @publisher)
      end
    end

    context "publisher with campaign" do
      setup do
        @publisher_with_no_group = Factory(:publisher, :publishing_group => nil, 
                                           :send_litle_campaign => true,
                                           :merchant_account_id => "TestMID")
      end

      should "return the MID and daily deal id" do
        fields = { :custom_fields => {
          :litle_report_group => "TestMID",
          :litle_campaign => @daily_deal.id }}

        assert_equal fields, braintree_custom_field_attrs(@daily_deal.id, @publisher_with_no_group)
      end
    end

    context "publishing group without campaign" do
      setup do
        @publisher.publishing_group.update_attribute(:send_litle_campaign, false)
      end

      should "return the MID and deal id as if publisher has a campaign" do
        fields = { :custom_fields => {
          :litle_report_group => "TestMID",
          :litle_campaign => @daily_deal.id }}

        assert_equal fields, braintree_custom_field_attrs(@daily_deal.id, @publisher)
      end

      should "return only the campaign/publishing group as litle_report_group if publisher's send_litle_campaign is false" do
        @publisher.update_attribute(:send_litle_campaign, false)
        fields = { :custom_fields => {

          :litle_report_group => "TestMID" }}

        assert_equal fields, braintree_custom_field_attrs(@daily_deal.id, @publisher)
      end
    end

    context "braintree_transaction_data - use_vault false" do

      setup do
        @purchase = Factory(:daily_deal_purchase)
      end

      should "call transaction_data with the right stuff" do
        redirect_url = "http://www.google.com"
        options = {
            :redirect_url => redirect_url,
            :use_vault => false
        }
        transaction = {
            :order_id => @purchase.analog_purchase_id,
            :type => 'sale',
            :options => {
                :submit_for_settlement => true
            },
            :amount => "%.2f" % @purchase.total_price,
            :custom_fields => { :litle_campaign => "BBD-#{@purchase.daily_deal.id}", :litle_report_group => nil } }
        Braintree::TransparentRedirect.expects(:transaction_data).with({ :redirect_url => redirect_url, :transaction => transaction })
        braintree_transaction_data(@purchase, options)
      end
    end

    context "braintree_transaction_data - customer NOT in vault" do

      setup do
        @purchase = Factory(:daily_deal_purchase)
      end

      should "call transaction_data with the right stuff" do
        redirect_url = "http://www.google.com"
        options = {
            :redirect_url => redirect_url,
            :use_vault => true
        }
        transaction = {
            :order_id => @purchase.analog_purchase_id,
            :type => 'sale',
            :options => {
              :submit_for_settlement => true,
              :add_billing_address_to_payment_method => true
            },
            :amount => "%.2f" % @purchase.total_price,
            :custom_fields => { :litle_campaign => "BBD-#{@purchase.daily_deal.id}", :litle_report_group => nil },
            :customer => { :id => @purchase.consumer.id_for_vault } }
        Braintree::TransparentRedirect.expects(:transaction_data).with({ :redirect_url => redirect_url, :transaction => transaction })
        braintree_transaction_data(@purchase, options)
      end
    end

    context "braintree_transaction_data - customer IS in vault" do
      setup do
        @purchase = Factory(:daily_deal_purchase)
        @purchase.consumer.in_vault = true
      end

      should "call transaction_data with the right stuff" do
        redirect_url = "http://www.google.com"
        options = {
          :redirect_url => redirect_url,
          :use_vault => true
        }
        transaction = {
            :order_id => @purchase.analog_purchase_id,
            :type => 'sale',
            :options => {
                :submit_for_settlement => true,
                :add_billing_address_to_payment_method => true
            },
            :amount => "%.2f" % @purchase.total_price,
            :custom_fields => { :litle_campaign => "BBD-#{@purchase.daily_deal.id}", :litle_report_group => nil },
            :customer_id => @purchase.consumer.id_for_vault }
        Braintree::TransparentRedirect.expects(:transaction_data).with({ :redirect_url => redirect_url, :transaction => transaction })
        braintree_transaction_data(@purchase, options)
      end

    end

  end

end

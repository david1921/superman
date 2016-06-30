require File.dirname(__FILE__) + "/../../../../test_helper"

# hydra class Reports::Advertisers::AdvertisersController::RefundedDailyDealsTest

module Reports
  module Advertisers
    module AdvertisersController
      class RefundedDailyDealsTest < ActionController::TestCase
        tests Reports::AdvertisersController
        include ActionView::Helpers::NumberHelper

        def setup
          @advertiser = Factory(:advertiser)
          login_as(Factory(:user, :company => @advertiser))
          @admin = Factory(:admin)
        end

        context "with off-platform purchase" do
          setup do
            @deal = Factory(:daily_deal, :advertiser => @advertiser)
            @purchase = Factory(:off_platform_daily_deal_purchase, :daily_deal => @deal)
            @purchase.capture!
            @purchase.partial_refund!(@admin, @purchase.daily_deal_certificate_ids)
          end

          should "render xml and include the certificate" do
            get :refunded_daily_deals, :id => @advertiser.id, :dates_end => 1.day.from_now, :dates_begin => 1.day.ago, :format => 'xml'
            assert_response :ok
            assert_template 'refunded_daily_deals.xml'
            assert_equal @purchase.daily_deal_certificates, assigns(:daily_deal_certificates)
          end
        end

        context "daily deal variations" do

          setup do
            login_as @admin
            @daily_deal = Factory(:daily_deal)
            @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

            @variation_1 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 40.00, :price => 30.00)
            @variation_2 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 30.00, :price => 20.00)
            @variation_3 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 20.00, :price => 10.00)

            @purchase_1  = Factory(:refunded_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 2, :daily_deal_variation => @variation_1)
            @purchase_2  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 1, :daily_deal_variation => @variation_2)
            @purchase_3  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :quantity => 3, :daily_deal_variation => @variation_3)        

            @advertiser  = @daily_deal.advertiser
          end

          context "xml" do

            setup do
              get :refunded_daily_deals, :id => @advertiser.id, :dates_end => 1.day.from_now, :dates_begin => 1.year.ago, :format => 'xml'
            end

            should "render appropriate data" do
              @daily_deal.daily_deal_purchases.each do |ddp|
                ddp.daily_deal_certificates.refunded.each do |cert|
                  assert_select "daily_deal_certificates daily_deal_certificate[daily_deal_certificate_id=#{cert.id}]" do
                    assert_select "customer_name", :text => ddp.consumer.name
                    assert_select "recipient_name", :text => cert.redeemer_name
                    assert_select "serial_number", :text => cert.serial_number
                    assert_select "currency_symbol", :text => cert.currency_symbol
                    assert_select "store_name", :text => ""
                    assert_select "value_proposition", :text => ddp.value_proposition
                    assert_select "value", :text => ddp.value.to_s
                    assert_select "price", :text => ddp.price.to_s
                    assert_select "refund_amount", :text => number_with_precision(cert.refund_amount, :precision => 2)
                  end
                end
              end
            end

          end

        end

      end
    end
  end
end


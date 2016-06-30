require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchaseHelperTest < ActionView::TestCase
  def test_daily_deal_purchase_location
    daily_deal_purchase = daily_deal_purchases(:changos)
    assert_equal nil, daily_deal_purchase_location(daily_deal_purchase), "No location"
    
    store = advertisers(:changos).stores.create!(
            :address_line_1 => "123 Main Street",
            :address_line_2 => "Suite 4",
            :city => "Hicksville",
            :state => "NY",
            :zip => "11801"
    )
    assert_equal nil, daily_deal_purchase_location(daily_deal_purchase), "Multiple stores. Location not required"
    
    daily_deals(:changos).update_attributes!(:location_required => true)
    assert_equal nil, daily_deal_purchase_location(daily_deal_purchase), "Multiple stores. Location required"
    
    daily_deal_purchase.store = store
    assert_equal " at 123 Main Street, Hicksville, NY",
                 daily_deal_purchase_location(daily_deal_purchase),
                 "Multiple stores. Location required. Store set on DailyDealPurchase."
  end
  
  context "admin_daily_deal_purchase_link" do
    context "when purchase is captured" do
      setup do
        @captured_purchase = Factory(:captured_daily_deal_purchase)
      end
      should "emit a Captured status" do
        assert_equal "Captured", admin_daily_deal_purchase_status_link(@captured_purchase)
      end
    end
    
    context "when purchase is authorized" do
      setup do
        @authorized_purchase = Factory(:authorized_daily_deal_purchase)
      end
      should "say Authorized" do
        assert_equal "Authorized", admin_daily_deal_purchase_status_link(@authorized_purchase)
      end
    end
    
    context "when purchase is voided" do
      setup do
        @voided_purchase = Factory(:voided_daily_deal_purchase)
      end
      should "say Voided" do
        assert_equal "Voided", admin_daily_deal_purchase_status_link(@voided_purchase)
      end
    end
    
    context "when purchase is fully refunded" do
      setup do
        @daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
        @daily_deal_purchase = full_refund(@daily_deal, 2)
      end
      should "say Refunded" do
        assert_equal "Refunded", admin_daily_deal_purchase_status_link(@daily_deal_purchase)
      end
    end
    
    context "when purchase is partially refunded" do
      setup do
        @daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
        @daily_deal_purchase = partial_refund(@daily_deal, 2, 30)
      end
      should "emit a Partially Refunded link" do
        assert_match /<a href=.*\.pdf.*Partially Refunded<\/a>/, admin_daily_deal_purchase_status_link(@daily_deal_purchase)
      end
    end
    
    context "when purchase is pending" do
      setup do
        @pending_purchase = Factory(:pending_daily_deal_purchase)
      end
      should "say Pending" do
        assert_equal "Pending", admin_daily_deal_purchase_status_link(@pending_purchase)
      end
    end
    
    context "when refunded but has active certificates" do
      setup do
        daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
        @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal)
        refunded_at = daily_deal.start_at + 6.hours
        @daily_deal_purchase.refunded_at = refunded_at
        @daily_deal_purchase.save!
        @daily_deal_purchase.reload
      end
      should "say Refunded" do
        assert_equal "Refunded", admin_daily_deal_purchase_status_link(@daily_deal_purchase)
      end
    end
    
  end
  
  context "print_daily_deal_purchase_link" do
    context "when purchase is captured" do
      context "without a class name" do
        setup do
          @captured_purchase = Factory(:captured_daily_deal_purchase)
        end
        should "emit a Print link" do
          assert_match /<a href=.*\.pdf.*print<\/a>/, print_daily_deal_purchase_link(@captured_purchase)
        end
      end

      context "with a class name" do
        setup do
          @captured_purchase = Factory(:captured_daily_deal_purchase)
        end
        should "emit a Print link" do
          assert_match /<a href=".*\.pdf\" class="foo">.*print<\/a>/, print_daily_deal_purchase_link(@captured_purchase, "foo")
        end
      end
    end
    
    context "when purchase is authorized" do
      setup do
        @authorized_purchase = Factory(:authorized_daily_deal_purchase)
      end
      should "say Needs To Complete Payment" do
        assert_equal "Needs To Complete Payment", print_daily_deal_purchase_link(@authorized_purchase)
      end
    end
    
    context "when purchase is voided" do
      setup do
        @voided_purchase = Factory(:voided_daily_deal_purchase)
      end
      should "say Voided" do
        assert_equal "Voided", print_daily_deal_purchase_link(@voided_purchase)
      end
    end
    
    context "when purchase is fully refunded" do
      setup do
        @daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
        @daily_deal_purchase = full_refund(@daily_deal, 2)
      end
      should "say Refunded" do
        assert_equal "Refunded", print_daily_deal_purchase_link(@daily_deal_purchase)
      end
    end
    
    context "when purchase is partially refunded" do
      context "without a class" do
        setup do
          @daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
          @daily_deal_purchase = partial_refund(@daily_deal, 2, 30)
        end
        should "emit a Print link" do
          assert_match /<a href=.*\.pdf.*print<\/a>/, print_daily_deal_purchase_link(@daily_deal_purchase)
        end
      end

      context "with a class" do
        setup do
          @daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
          @daily_deal_purchase = partial_refund(@daily_deal, 2, 30)
        end
        should "emit a Print link" do
          assert_match /<a href=".*\.pdf\" class="foo">.*print<\/a>/, print_daily_deal_purchase_link(@daily_deal_purchase, "foo")
        end
      end
    end
    
    context "when purchase is pending" do
      setup do
        @pending_purchase = Factory(:pending_daily_deal_purchase)
      end
      should "say Pending" do
        assert_equal "Pending", print_daily_deal_purchase_link(@pending_purchase)
      end
    end
    
    context "when refunded but has active certificates" do
      setup do
        daily_deal = Factory(:daily_deal, :value => 100, :price => 30)
        @daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => 2, :daily_deal => daily_deal)
        refunded_at = daily_deal.start_at + 6.hours
        @daily_deal_purchase.refunded_at = refunded_at
        @daily_deal_purchase.save!
        @daily_deal_purchase.reload
      end

      should "say Refunded" do
        assert_equal "Refunded", print_daily_deal_purchase_link(@daily_deal_purchase)
      end
    end

    context 'with an OffPlatformDailyDealCertificate which has a voucher pdf attachment' do
      setup do
        @cert = Factory(:off_platform_daily_deal_certificate)
        @cert.download_url = nil
        paperclip_attachment = mock('voucher pdf', :url => 'http://beef.pork.com/test.pdf')
        @cert.stubs(:voucher_pdf).returns(paperclip_attachment)
        @cert.stubs(:has_voucher_pdf?).returns(true)
      end
      should "emit a Print link" do
        assert_match "<a href=\"http://beef.pork.com/test.pdf\" target=\"_blank\">Print</a>", print_daily_deal_purchase_link(@cert)
      end
    end

    context "with a Travelsavers purchase" do
      
      should "show 'Needs To Complete Payment' for a Travelsavers purchase in the 'authorized' state" do
        booking_with_authorized_purchase = Factory :travelsavers_booking_with_vendor_retrieval_errors
        assert booking_with_authorized_purchase.daily_deal_purchase.authorized?
        assert_equal "Needs To Complete Payment", print_daily_deal_purchase_link(booking_with_authorized_purchase.daily_deal_purchase)
      end

      should "show a 'Resend Email' link for a Travelsavers purchase in the 'captured' state" do
        booking_with_captured_purchase = Factory :successful_travelsavers_booking
        assert booking_with_captured_purchase.daily_deal_purchase.captured?
        assert_equal link_to("Resend email", resend_email_daily_deal_purchase_path(booking_with_captured_purchase.daily_deal_purchase), :method => :post),
                     print_daily_deal_purchase_link(booking_with_captured_purchase.daily_deal_purchase)
      end
    end
  end
  
  private
  
  def partial_refund(daily_deal, quantity, refund_amount)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => quantity, :daily_deal => daily_deal)
    expect_braintree_partial_refund(daily_deal_purchase, refund_amount)
    daily_deal_purchase.partial_refund!(Factory(:admin), [daily_deal_purchase.daily_deal_certificates.first.id.to_s])
    refunded_at = daily_deal.start_at + 6.hours
    daily_deal_purchase.update_attributes!(:refunded_at => refunded_at)
    daily_deal_purchase.daily_deal_certificates.first.update_attributes!(:refunded_at => refunded_at)
    assert daily_deal_purchase.partially_refunded?
    daily_deal_purchase
  end
  
  def full_refund(daily_deal, quantity)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => quantity, :daily_deal => daily_deal)
    expect_braintree_full_refund(daily_deal_purchase)
    daily_deal_purchase.void_or_full_refund!(Factory(:admin))
    refunded_at = daily_deal.start_at + 6.hours
    daily_deal_purchase.update_attributes!(:refunded_at => refunded_at)
    daily_deal_purchase.daily_deal_certificates.each { |c| c.update_attributes!(:refunded_at => refunded_at) }
    assert daily_deal_purchase.fully_refunded?
    daily_deal_purchase
  end

end

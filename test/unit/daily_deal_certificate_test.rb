require File.dirname(__FILE__) + "/../test_helper"

class DailyDealCertificateTest < ActiveSupport::TestCase
  should belong_to(:daily_deal_purchase)

  def test_validate_presence_of_daily_deal_purchase
    daily_deal_certificate = Factory :daily_deal_certificate
    assert daily_deal_certificate.valid?
    daily_deal_certificate.daily_deal_purchase = nil
    assert daily_deal_certificate.invalid?
  end

  def test_validate_presence_of_redeemer_name
    daily_deal_certificate = Factory :daily_deal_certificate
    assert daily_deal_certificate.valid?
    daily_deal_certificate.redeemer_name = nil
    assert daily_deal_certificate.invalid?
  end

  def test_create
    daily_deal_certificate = daily_deal_purchases(:changos).daily_deal_certificates.create!(:redeemer_name => "John Public")
    assert_equal "John Public", daily_deal_certificate.redeemer_name
    assert_match(/\A\d{4}-\d{4}\z/, daily_deal_certificate.serial_number)
    assert_equal nil, daily_deal_certificate.store, "store"
    assert_equal "active", daily_deal_certificate.status
  end

  def test_create_with_store
    daily_deal_purchase = daily_deals(:changos).daily_deal_purchases.build
    daily_deal_purchase.consumer = users(:john_public)
    daily_deal_purchase.store = stores(:changos)
    daily_deal_purchase.save!
    daily_deal_certificate = daily_deal_purchase.daily_deal_certificates.create!(:redeemer_name => "John Public")
    assert_equal "John Public", daily_deal_certificate.redeemer_name
    assert_match(/\A\d{4}-\d{4}\z/, daily_deal_certificate.serial_number)
    assert_equal stores(:changos), daily_deal_certificate.store, "store"
  end

  def test_create_with_duplicate_serial_number
    daily_deal_certificate = daily_deal_purchases(:changos).daily_deal_certificates.create(:redeemer_name => "John Public", :serial_number => "1234-5678")
    new_daily_deal_certificate = daily_deal_purchases(:changos).daily_deal_certificates.create(:redeemer_name => "Suzy Public")
    new_daily_deal_certificate.update_attribute(:serial_number, "1234-5678")
    assert_equal daily_deal_certificate.serial_number, new_daily_deal_certificate.serial_number
    assert !new_daily_deal_certificate.valid?, "should not be valid with duplicate serial number"
  end

  # this test reproduces the error outlined here: https://www.pivotaltracker.com/story/show/10160941
  # seems to work fine in when creating certificates in outside of block (see test above)
  def test_create_with_duplicate_serial_number_within_block
    daily_deal_purchase = daily_deal_purchases(:changos)
    daily_deal_purchase.daily_deal_certificates.destroy_all
    assert_equal 0, daily_deal_purchase.daily_deal_certificates.size
    DailyDealCertificate.any_instance.stubs(:random_serial_number).returns("1234-5678")
    assert_raise RuntimeError do
      (0..1).each do |i|
        daily_deal_purchase.daily_deal_certificates.create!(:redeemer_name => "John #{i}")
      end
    end
    assert_equal 1, daily_deal_purchase.daily_deal_certificates.size
  end

  def test_create_with_duplicate_serial_number_with_unique_serial_number_is_able_to_produce_a_unique_serial_number_before_max_attempts
    assert DailyDealCertificate.find_by_serial_number("1234-5678").nil?, "At start of test there should be no records with the serial number 1234-5678"
    DailyDealCertificate.any_instance.stubs(:random_serial_number).returns("1234-5678")
    daily_deal_certificate = daily_deal_purchases(:changos).daily_deal_certificates.create(:redeemer_name => "John Public")
    assert daily_deal_certificate.valid?, "errors: #{daily_deal_certificate.errors.full_messages.inspect}"

    # first two attempts, random_serial_number returns a serial number that already exists
    DailyDealCertificate.any_instance.stubs(:random_serial_number).returns("1234-5678", "1234-5678", "4578-9999")
    new_daily_deal_certificate = daily_deal_purchases(:changos).daily_deal_certificates.create(:redeemer_name => "Suzy Public")
    assert_equal "4578-9999", new_daily_deal_certificate.serial_number
    assert new_daily_deal_certificate.valid?, "errors: #{daily_deal_certificate.errors.full_messages.inspect}"
  end

  test "with_bar_code_image" do
    daily_deal_certificate = daily_deal_purchases(:changos).daily_deal_certificates.create!(:redeemer_name => "John Public", :bar_code => "abcd1234")
    daily_deal_certificate.with_bar_code_image(daily_deal_certificate.bar_code) do |file|
      assert file.is_a?(IO)
    end

    file = daily_deal_certificate.with_bar_code_image(daily_deal_certificate.bar_code, :keep_jpg => true)
    assert File.exists?(file)
    assert File.unlink(file)
  end

  context "status validation" do
    setup do
      @certificate = Factory(:daily_deal_certificate)
    end
    context "works for proper values" do
      should "be able to set to active" do
        @certificate.status = "active"
        assert_valid @certificate
      end
      should "be able to set to redeemed" do
        @certificate.status = "redeemed"
        assert_valid @certificate
      end
      should "be able to set to refunded" do
        @certificate.refund!
        assert_valid @certificate
      end
      should "be able to set to voided" do
        @certificate.status = "voided"
        assert_valid @certificate
      end
    end
    context "improper values" do
      should "not be valid" do
        @certificate.status = "pending"
        assert !@certificate.valid?
        @certificate.status = "authorized"
        assert !@certificate.valid?
        @certificate.status = "captured"
        assert !@certificate.valid?
        @certificate.status = "foobar"
        assert !@certificate.valid?
      end
    end
  end

  context "refund, void, and activate" do
    setup do
      @certificate = Factory(:daily_deal_certificate, :actual_purchase_price => 10)
    end
    should "be setup properly" do
      assert_equal "active", @certificate.status
    end
    should "set status on refund" do
      @certificate.refund!
      assert_equal "refunded", @certificate.status
      assert_equal 10, @certificate.refund_amount
      assert_not_nil @certificate.refunded_at
    end
    should "set status on void" do
      @certificate.void!
      assert_equal "voided", @certificate.status
      assert_equal 0, @certificate.refund_amount
    end
    should "set status on activate" do
      @certificate.activate!
      assert_equal "active", @certificate.status
    end
  end

  context "#redeemed named_scope" do
    setup do
      @ddc1 = Factory(:daily_deal_certificate)
      @ddc2 = Factory(:daily_deal_certificate)
      @ddc1.redeem!
    end

    should "return only redeemed daily deal certificates" do
      redeemed_certs = DailyDealCertificate.redeemed.all
      assert redeemed_certs.include?(@ddc1)
      assert !redeemed_certs.include?(@ddc2)
    end
  end
  
  context "#value" do
    
    setup do
      @deal = Factory :daily_deal, :price => 30, :value => 50
    end
    
    context "when DailyDeal#certificates_to_generate_per_unit_quantity == 1" do
      
      should "be equal to the value of the deal" do
        @deal.update_attributes! :certificates_to_generate_per_unit_quantity => 1
        purchase = Factory :captured_daily_deal_purchase, :daily_deal => @deal, :quantity => 3
        assert_equal 50, purchase.daily_deal_certificates.first.value
      end
      
    end
    
    context "when DailyDeal#certificates_to_generate_per_unit_quantity > 1" do
      
      should "be equal to the value of the deal divided by certificates_to_generate_per_unit_quantity" do
        @deal.update_attributes! :certificates_to_generate_per_unit_quantity => 3
        purchase = Factory :captured_daily_deal_purchase, :daily_deal => @deal, :quantity => 2
        assert_equal 16.67, purchase.daily_deal_certificates.first.value
      end
      
    end
    
  end

  context "redeemable?" do
    
    context "captured purchase" do
      setup do
        @captured_purchased = Factory(:captured_daily_deal_purchase)
      end

      context "certificate with captured purchase" do
        setup do
          @certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => @captured_purchased)
        end
        should "have correct setup" do
          assert_equal "captured", @certificate.daily_deal_purchase.payment_status
          assert_nil @certificate.redeemed_at
        end

        context "when not redeemed and captured" do
          should "be redeembable" do
            assert @certificate.redeemable?
          end
        end

        context "when already reedemeed" do
          setup do
            @certificate.status = "redeemed"
          end
          should "not be redeemable" do
            assert !@certificate.redeemable?
          end
        end
      end
    end

    context "authorized purchase" do
      setup do
        @authorized_purchase = Factory(:authorized_daily_deal_purchase)
      end
      context "certificate with authorized purchcase" do
        setup do
          @certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => @authorized_purchase)
        end
        should "not be redeemable" do
          assert !@certificate.redeemable?
        end
      end
    end
    
    context "refunded purchase" do
      setup do
        @refunded_purchase = Factory(:refunded_daily_deal_purchase)
      end
      context "certificate with refunded_purchase purchcase" do
        setup do
          @certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => @refunded_purchase)
        end
        should "not be redeemable" do
          assert !@certificate.redeemable?
        end
      end
    end
    
    context "loyalty program refunded purchase" do
      setup do
        @admin = Factory(:admin)
        @publisher = publisher_with_loyalty_program_enabled
        @daily_deal = deal_with_loyalty_program_enabled(@publisher)
        @loyalty_credited_purchase = purchase_that_earned_loyalty_credit_and_has_received_the_credit(@daily_deal, Factory(:consumer, :publisher => @publisher))
      end
      
      context "certificate with captured purchase" do
        setup do
          assert @loyalty_credited_purchase.daily_deal_certificates.size == 1
          @certificate = @loyalty_credited_purchase.daily_deal_certificates.first
        end
        should "have correct setup" do
          assert_equal "refunded", @certificate.daily_deal_purchase.payment_status
        end
        
        context "when not redeemed and refunded" do
          should "be redeembable" do
            assert @certificate.redeemable?
          end
        end
        
        context "when reedemeed" do
          setup do
            @certificate.status = "redeemed"
          end
          should "not be redeemable" do
            assert !@certificate.redeemable?
          end
        end
      end
    end
    
  end

  context "refundable?" do
    context "cert is active" do
      setup do
        @certificate = Factory(:daily_deal_certificate)
      end
      should "be active" do
        assert_equal @certificate.status, "active"
      end
      should "be refundable" do
        assert @certificate.refundable?
      end
    end
    context "cert is redeemed" do
      setup do
        @certificate = Factory(:daily_deal_certificate, :status => "redeemed")
      end
      should "not be refundable" do
        assert !@certificate.refundable?
      end
    end
    context "cert is voided" do
      setup do
        @certificate = Factory(:daily_deal_certificate, :status => "voided")
      end
      should "not be refundable" do
        assert !@certificate.refundable?
      end
    end
  end

  context "redeem!" do
    context "cert is redeemable" do
      setup do
        @captured_purchased = Factory(:captured_daily_deal_purchase)
        @certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => @captured_purchased)
      end
      should "have proper setup" do
        assert_equal "active", @certificate.status
        assert_nil @certificate.redeemed_at
        assert @certificate.redeemable?
      end
      should "redeem and update state properly" do
        @certificate.redeem!
        assert_not_nil @certificate.redeemed_at
        assert @certificate.redeemed?
        assert_equal "redeemed", @certificate.status
        assert !@certificate.redeemable?
      end
    end
  end

  context "refunded and refunded_between named scope" do
    setup do
      Timecop.freeze(2.days.ago) do
        @purchase = Factory(:refunded_daily_deal_purchase, :quantity => 3)
      end
    end

    context "refunded" do
      should "return all the refunded certs with no dates" do
        assert_equal 3, DailyDealCertificate.refunded.size
      end
    end

    context "#refunded_between" do
      should "return all the refunded certs with a suitable date range" do
        assert_equal 3, DailyDealCertificate.refunded_between(3.days.ago..1.day.ago).size
      end
      should "return none if the dates are long ago" do
        assert_equal 0, DailyDealCertificate.refunded_between(6.days.ago..4.days.ago).size
      end
    end
  end

  context "pdf generation" do

    context "with deals that aren't syndicated" do

      context "with default template" do

        setup do
          certificate = Factory :daily_deal_certificate
          receiver = PageTextReceiver.new
          PDF::Reader.string(certificate.to_pdf, receiver)
          @pdf_content = receiver.content.first
        end

        should "add the standard voucher fields" do
          assert_match /recipient/i, @pdf_content
          assert_match /expires on/i, @pdf_content
          assert_match /fine print/i, @pdf_content
          assert_match /redeem at/i, @pdf_content
        end

        should "NOT add a 'Deal provided by:' label for the syndication source publisher's logo to the voucher" do
          assert_no_match /deal provided by/i, @pdf_content
        end

      end

      context "with custom template for Time Warner Cable (rr) publishing group" do

        setup do
          publishing_group  = Factory(:publishing_group, :label => 'rr')
          publisher         = Factory(:publisher, :label => 'clickedin-austin', :publishing_group => publishing_group)
          @deal              = Factory(:daily_deal, :publisher => publisher, :hide_serial_number_if_bar_code_is_present => true)
          @certificate       = Factory :daily_deal_certificate, :daily_deal_purchase => Factory(:captured_daily_deal_purchase, :daily_deal => @deal)
          @certificate_with_barcode = Factory :daily_deal_certificate, :daily_deal_purchase => Factory(:captured_daily_deal_purchase, :daily_deal => @deal), :bar_code => "CLICK2BYQVQ"
        end

        should "use the app/views/themes/rr/daily_deal_purchases/certificate_layout.html.erb for custom_voucher_template_layout_path" do
          assert_equal Rails.root.join("app/views/themes/rr/daily_deal_purchases/certificate_layout.html.erb"), @certificate.daily_deal_purchase.custom_voucher_template_layout_path
        end

        should "use the app/views/themes/rr/daily_deal_purchases/_certificate_body.html.erb for custom_voucher_template_path" do
          assert_equal Rails.root.join("app/views/themes/rr/daily_deal_purchases/_certificate_body.html.erb"), @certificate.daily_deal_purchase.custom_voucher_template_path
        end

        should "render the serial number for a certificate that does not have a bar code" do
          assert_match(%r{<span class="voucher_number">\w+</span>}, @certificate.custom_lay_out_as_html_snippet)
        end

        should "hide the serial number for a certificate that has a bar code" do
          assert_match(%r{<span class="voucher_number"></span>}, @certificate_with_barcode.custom_lay_out_as_html_snippet)
        end

        should "render the serial number for a certificate that has a bar code, if " +
               "hide_serial_number_if_bar_code_is_present is false" do
          @certificate_with_barcode.daily_deal.hide_serial_number_if_bar_code_is_present = false
          assert_match(%r{<span class="voucher_number">\w+</span>}, @certificate_with_barcode.custom_lay_out_as_html_snippet)
        end

      end

    end

    context "with syndicated deals, cobranding disabled" do
      setup do
        source_deal = Factory :daily_deal, :cobrand_deal_vouchers => false, :available_for_syndication => true
        syndicated_publisher = Factory :publisher
        syndicated_deal = syndicate source_deal, syndicated_publisher

        certificate = Factory :daily_deal_certificate, :daily_deal_purchase => Factory(:captured_daily_deal_purchase, :daily_deal => syndicated_deal)
        receiver = PageTextReceiver.new
        PDF::Reader.string(certificate.to_pdf, receiver)

        @pdf_content = receiver.content.first
      end

      should "add the standard voucher fields" do
        assert_match /recipient/i, @pdf_content
        assert_match /expires on/i, @pdf_content
        assert_match /fine print/i, @pdf_content
        assert_match /redeem at/i, @pdf_content
      end

      should "NOT add a 'Deal provided by:' label for the syndication source publisher's logo to the voucher" do
        assert_no_match /deal provided ?by/i, @pdf_content
      end

    end

    context "with syndicated deals, cobranding enabled" do
      setup do
        source_deal = Factory :daily_deal, :cobrand_deal_vouchers => true, :available_for_syndication => true
        syndicated_publisher = Factory :publisher
        syndicated_deal = syndicate source_deal, syndicated_publisher

        certificate = Factory :daily_deal_certificate, :daily_deal_purchase => Factory(:captured_daily_deal_purchase, :daily_deal => syndicated_deal)
        receiver = PageTextReceiver.new
        PDF::Reader.string(certificate.to_pdf, receiver)

        @pdf_content = receiver.content.first

      end

      should "add the standard voucher fields" do
        assert_match /recipient/i, @pdf_content
        assert_match /expires on/i, @pdf_content
        assert_match /fine print/i, @pdf_content
        assert_match /redeem at/i, @pdf_content
      end

      should "add a 'Deal provided by:' label for the syndication source publisher's logo to the voucher" do
        assert_match /deal provided ?by:/i, @pdf_content
      end
    end

    context "with syndicated deals that use custom voucher templates (e.g. deals sourced from doubletakedeals)" do

      setup do
        @source_publisher = Factory :publisher, :label => "doubletakedeals"
        @advertiser = Factory :advertiser, :publisher => @source_publisher, :name => "Test Advertiser"
        @source_deal = Factory :daily_deal, :advertiser => @advertiser, :available_for_syndication => true
        Factory :third_party_deals_api_config, :publisher => @source_deal.publisher
        @syndicated_publisher = Factory :publisher
        @syndicated_deal = syndicate(@source_deal, @syndicated_publisher)
      end

      should "generate a single voucher when the purchase quantity is one" do
        test_serials = OpenStruct.new(:serial_numbers => ["TEST-SERIAL-1"])
        ::DailyDealPurchase.any_instance.stubs(:get_third_party_serial_numbers_and_possibly_mark_deal_soldout!).returns(test_serials)
        @purchase = Factory :captured_daily_deal_purchase, :daily_deal => @syndicated_deal
        pdf_text = extract_text_from_pdf(@purchase.daily_deal_certificates_pdf)
        assert_match /TEST-SERIAL-1/, pdf_text
        assert_equal 1, pdf_text.scan(/Legal Stuff We Have To Say/x).length
        assert_equal 1, pdf_text.scan(/merchant named above \(Test Advertiser\)/x).length
      end

      should "remove the barcode file when the voucher rendering is complete" do
        test_serials = OpenStruct.new(:serial_numbers => ["TEST-SERIAL-1"])
        ::DailyDealPurchase.any_instance.stubs(:get_third_party_serial_numbers_and_possibly_mark_deal_soldout!).returns(test_serials)
        @purchase = Factory :captured_daily_deal_purchase, :daily_deal => @syndicated_deal
        @purchase.daily_deal_certificates_pdf
        @purchase.daily_deal_certificates.each do |ddc|
          assert !File.exists?(Rails.root.join("tmp", "daily_deal_certificate-#{ddc.id}-barcode.jpg"))
        end
      end

      should "generate 3 vouchers when the purchase quantity is three" do
        test_serials = OpenStruct.new(:serial_numbers => ["TEST-SERIAL-1", "TEST-SERIAL-2", "TEST-SERIAL-3"])
        ::DailyDealPurchase.any_instance.stubs(:get_third_party_serial_numbers_and_possibly_mark_deal_soldout!).returns(test_serials)
        @purchase = Factory :captured_daily_deal_purchase, :quantity => 3, :daily_deal => @syndicated_deal
        pdf_text = extract_text_from_pdf(@purchase.daily_deal_certificates_pdf)
        assert_match /TEST-SERIAL-1/, pdf_text
        assert_match /TEST-SERIAL-2/, pdf_text
        assert_match /TEST-SERIAL-3/, pdf_text
        assert_equal 3, pdf_text.scan(/Legal Stuff We Have To Say/x).length
        assert_equal 3, pdf_text.scan(/merchant named above \(Test Advertiser\)/x).length
      end

    end

  end

  context "#map_image_url" do
    should "return the google map api url for store" do
      ddc = Factory(:daily_deal_certificate)
      location = ddc.advertiser.store
      escaped_address = CGI.escape("#{location.address_line_1}, #{location.city}, #{location.state} #{location.zip}")
      assert_equal "http://maps.google.com/maps/api/staticmap?size=305x250&center=#{escaped_address}&markers=size:small|#{escaped_address}&key=ABQIAAAAzObGV3GscSCtMupcN2Jm-RSSjhI9lG3KGwm-Keiwru5ERTctHhTXe3LfYrff_rQT8DZgaQB6AthF0A&sensor=false",
                    ddc.map_image_url
    end
  end

  context "#pdf_filename" do
    should "be the redeemer name, advertiser name, and the certificate id (separated by underscore) dot pdf" do
      ddc = Factory(:daily_deal_certificate)
      assert_equal ddc.pdf_filename, [ddc.redeemer_name, ddc.advertiser.name, ddc.id.to_s].join("_").to_ascii.split.join('_').downcase << ".pdf"
    end
  end

  context "voucher_has_qr_code" do
    setup do
      @daily_deal_certificate = Factory(:daily_deal_certificate)
    end

    should "equal the delegated value" do
      @daily_deal_certificate.daily_deal.voucher_has_qr_code = true
      assert @daily_deal_certificate.voucher_has_qr_code?, "Should equal delegated value when true"

      @daily_deal_certificate.daily_deal.voucher_has_qr_code = false
      assert !@daily_deal_certificate.voucher_has_qr_code?, "Should equal delegated value when false"
    end
  end

  context "delegates" do

    setup do
      @certificate = Factory(:daily_deal_certificate)
    end
    should "delegate #bar_code_symbology to the deal" do
      format = @certificate.daily_deal.bar_code_symbology
      assert format.present?
      assert_equal format, @certificate.bar_code_symbology
    end

    should "delegate value_proposition, value, and price to daily deal purchase" do
      daily_deal_purchase = mock("daily_deal_purchase")
      @certificate.expects(:daily_deal_purchase).at_least_once.returns(daily_deal_purchase)

      daily_deal_purchase.expects(:value_proposition).returns("The Value Prop")
      assert_equal "The Value Prop", @certificate.value_proposition

      daily_deal_purchase.expects(:value).returns(600.00)
      daily_deal_purchase.expects(:certificates_to_generate_per_unit_quantity).returns(@certificate.daily_deal.certificates_to_generate_per_unit_quantity)
      assert_equal 600.00, @certificate.value

      daily_deal_purchase.expects(:humanize_value).returns("$600")
      assert_equal "$600", @certificate.humanize_value

      daily_deal_purchase.expects(:price).returns(300.00)
      assert_equal 300.00, @certificate.price
    end
  end
  
  context "#active named_scope" do
    setup do
      @admin = Factory(:admin)
      @ddc1 = Factory(:daily_deal_certificate)
      @ddc2 = Factory(:refunded_daily_deal_certificate, :daily_deal_purchase => Factory(:daily_deal_purchase))
      
      @publisher = publisher_with_loyalty_program_enabled
      @daily_deal = deal_with_loyalty_program_enabled(@publisher)
      @ddp_loyalty = purchase_that_earned_loyalty_credit_and_has_received_the_credit(@daily_deal, Factory(:consumer, :publisher => @publisher))
    end
    
    should "return only active and refunded loyalty program daily deal certificates" do
      active_certs = DailyDealCertificate.active
      assert active_certs.include?(@ddc1)
      assert !active_certs.include?(@ddc2)
      assert @ddp_loyalty.daily_deal_certificates.size == 1
      assert active_certs.include?(@ddp_loyalty.daily_deal_certificates.first)
    end
  end
  
  context "#validatable named_scope" do
    
    setup do
      @captured_purchased = Factory(:captured_daily_deal_purchase)
      @captured_certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => @captured_purchased)
      @authorized_purchase = Factory(:authorized_daily_deal_purchase)
      @authorized_certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => @authorized_purchase)
      @refunded_purchase = Factory(:refunded_daily_deal_purchase)
      @refunded_certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => @refunded_purchase)
      
      @redeemed_purchased = Factory(:captured_daily_deal_purchase)
      @redeemed_certificate = Factory(:daily_deal_certificate, :daily_deal_purchase => @redeemed_purchased)
      @redeemed_certificate.redeem!
      
      @admin = Factory(:admin)
      @publisher = publisher_with_loyalty_program_enabled
      @daily_deal = deal_with_loyalty_program_enabled(@publisher)
      @loyalty_credited_purchase = purchase_that_earned_loyalty_credit_and_has_received_the_credit(@daily_deal, Factory(:consumer, :publisher => @publisher))
      @loyalty_credited_certificate = @loyalty_credited_purchase.daily_deal_certificates.first
    end
    
    should "have certificates for active captured, redeemed and loyalty credited certificates" do
      certs = DailyDealCertificate.validatable
      assert certs.include?(@captured_certificate)
      assert certs.include?(@redeemed_certificate)
      assert certs.include?(@loyalty_credited_certificate)
      assert !certs.include?(@authorized_certificate)
      assert !certs.include?(@refunded_certificate)
    end
    
    context "redeemed loyalty credited certificate" do
      setup do
        @loyalty_credited_certificate.redeem!
      end
      
      should "be returned" do
        certs = DailyDealCertificate.validatable
        assert certs.include?(@loyalty_credited_certificate)
      end
    end

  end

  context "not_travelsavers named scope" do
    
    should "exclude certificates attached to TS bookings" do
      DailyDealCertificate.delete_all
      ts_booking = Factory :successful_travelsavers_booking
      ts_cert = ts_booking.daily_deal_purchase.daily_deal_certificates.first

      non_ts_purchase = Factory :captured_daily_deal_purchase
      non_ts_cert = non_ts_purchase.daily_deal_certificates.first

      assert_same_elements [ts_cert, non_ts_cert], DailyDealCertificate.all
      assert_equal [non_ts_cert], DailyDealCertificate.not_travelsavers
    end
  end

  private

  def syndicate(daily_deal, syndicated_publisher)
    daily_deal.update_attribute(:available_for_syndication, true)
    daily_deal.syndicated_deals.build(:publisher_id => syndicated_publisher.id)
    daily_deal.save!
    daily_deal.syndicated_deals.last
  end

end

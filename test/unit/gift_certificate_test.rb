require File.dirname(__FILE__) + "/../test_helper"

class GiftCertificateTest < ActiveSupport::TestCase
  def setup
    assign_valid_attributes
    GiftCertificateMailer.expects(:deliver_gift_certificate).at_least(0).returns(nil)
  end
  
  def test_create
    gift_certificate = GiftCertificate.create!(@valid_attributes)
    @valid_attributes.keys.each { |attr| assert_equal @valid_attributes[attr], gift_certificate.send(attr), attr.to_s }
  end
  
  def test_required_attributes
    assert_required = lambda do |attr, test_blank|
      gift_certificate = GiftCertificate.new(@valid_attributes.except(attr))
      assert gift_certificate.invalid?, "Should not be valid with missing #{attr}"
      assert gift_certificate.errors.on(attr), "Should have error on #{attr} when missing"

      if test_blank
        gift_certificate = GiftCertificate.new(@valid_attributes.merge(attr => " "))
        assert gift_certificate.invalid?, "Should not be valid with blank #{attr}"
        assert gift_certificate.errors.on(attr), "Should have error on #{attr} when blank"
      end
    end
    assert_required.call :advertiser, false
    assert_required.call :message, true
    assert_required.call :value, true
    assert_required.call :price, true
    assert_required.call :number_allocated, true
  end
  
  def test_validation_of_number_allocated
    assert_invalid_attr_value :number_allocated, "X"
    assert_invalid_attr_value :number_allocated, -1.5
    assert_invalid_attr_value :number_allocated, -1
    assert_invalid_attr_value :number_allocated, 1.5
  end
  
  def test_number_allocated_is_valid_when_zero
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:number_allocated => "0"))
    assert_equal 0, gift_certificate.number_allocated
  end
  
  def test_validation_of_price_and_value
    [:price, :value].each do |attr|
      assert_invalid_attr_value attr, 0
      assert_invalid_attr_value attr, 0.00
      assert_invalid_attr_value attr, -1
      assert_invalid_attr_value attr, -1.00
      assert_invalid_attr_value attr, "$0"
      assert_invalid_attr_value attr, "$0.00"
      assert_invalid_attr_value attr, "-$1"
      assert_invalid_attr_value attr, "-$1.00"
    end
  end
  
  def test_price_must_be_at_least_value
    assert GiftCertificate.new(@valid_attributes.merge(:price => 3.99, :value => 3.99)).valid?

    gift_certificate = GiftCertificate.new(@valid_attributes.merge(:price => 4.00, :value => 3.99))
    assert gift_certificate.invalid?
    assert_match /cannot be greater than/, gift_certificate.errors.on(:price)
  end
  
  test "should have advertiser association" do
    assert GiftCertificate.reflect_on_association(:advertiser)
  end
  
  test "should have publisher association" do
    assert GiftCertificate.reflect_on_association( :publisher )
  end
  
  test "should have purchased_gift_certificates association" do
    assert GiftCertificate.reflect_on_association( :purchased_gift_certificates )
  end
  
  test "should default deleted to false" do
    gift_certificate = GiftCertificate.create!( @valid_attributes )
    assert !gift_certificate.deleted?
  end
            
  def test_should_store_price_as_float
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => "20"))
    gift_certificate.reload
    assert_equal 20.00, gift_certificate.price
  end

  def test_should_store_value_as_float
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:value => "20"))
    gift_certificate.reload
    assert_equal 20.00, gift_certificate.value
  end
  
  def test_avaiable_count_and_available
    GiftCertificate.destroy_all
    
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:number_allocated => 5))
    assert_equal 5, gift_certificate.available_count
    assert gift_certificate.available?
    assert_equal 1, GiftCertificate.available.count
    
    purchase gift_certificate, 3
    assert_equal 2, gift_certificate.available_count
    assert gift_certificate.available?
    
    purchase gift_certificate, 2
    assert_equal 0, gift_certificate.available_count
    assert !gift_certificate.available?
    
    purchase gift_certificate, 3
    assert_equal -3, gift_certificate.available_count
    assert !gift_certificate.available?
  end

  def test_available_count_and_available_when_deleted
    GiftCertificate.destroy_all
    
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:number_allocated => 5))
    assert_equal 5, gift_certificate.available_count
    assert gift_certificate.available?
    assert_equal 1, GiftCertificate.available.count

    gift_certificate.update_attributes! :deleted => true
    assert_equal 0, gift_certificate.available_count
    assert !gift_certificate.available?
    assert_equal 0, GiftCertificate.available.count
  end
  
  def test_purchased_count
    gift_certificate = GiftCertificate.create!(@valid_attributes)
    purchase gift_certificate, 3
    assert_equal 3, gift_certificate.purchased_count
  end
  
  def test_active_named_scope_with_no_active_gift_certificate
    gift_certificate = GiftCertificate.create!( @valid_attributes.merge( :expires_on => 2.day.ago ) )
    assert gift_certificate.expired?
    
    assert_equal 0, GiftCertificate.active.size    
  end
  
  def test_active_named_scope_with_gift_certificate_with_no_expired_on_date
    gift_certificate = GiftCertificate.create!( @valid_attributes )
    assert !gift_certificate.expired?, "should not be expired"
    
    assert_equal 1, GiftCertificate.active.size
  end
  
  def test_active_named_scope_with_gift_certificate_with_expired_on_date_in_the_future
    gift_certificate = GiftCertificate.create!( @valid_attributes.merge( :expires_on => 2.day.from_now ) )
    assert !gift_certificate.expired?, "should not be expired"
    
    assert_equal 1, GiftCertificate.active.size
  end

  def test_active_with_show_on_time
    assert_equal 0, GiftCertificate.active.size
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:show_on => Time.local(2009, 4, 1, 23, 30, 0)))

    Time.stubs(:now).returns(Time.local(2009, 4, 1, 23, 29, 0))
    assert_equal 0, GiftCertificate.active.size

    Time.stubs(:now).returns(Time.local(2009, 4, 1, 23, 40, 0))
    assert_equal 1, GiftCertificate.active.size
  end
  
  def test_active_with_starting_on_for_gift_certificate_that_has_started
    gift_certificate = GiftCertificate.create!( @valid_attributes.merge(:show_on => Time.local(2010, 05, 28, 9, 0, 0)) )
    
    Time.stubs(:now).returns(Time.local(2010, 5, 28, 10, 0, 0 ) )
    nextday = Time.local(2010, 5, 29, 10, 0, 0)
    assert_equal 0, GiftCertificate.starting_on( nextday ).size    
  end
  
  def test_active_with_starting_on_for_gift_certifcate_that_has_not_started
    gift_certificate = GiftCertificate.create!( @valid_attributes.merge(:show_on => Time.local(2010, 05, 28, 9, 0, 0)) )
        
    Time.stubs(:now).returns(Time.local(2010, 5, 27, 18, 10, 0))
    nextday = Time.local(2010, 5, 28, 18, 10, 0)         
    assert_equal 1, GiftCertificate.starting_on( nextday ).size
  end
  
  
  def test_allow_dollar_signs_in price
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => "$4"))
    assert_equal 4.00, gift_certificate.price, "price"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => "$4.25"))
    assert_equal 4.25, gift_certificate.price, "price"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => "4.25"))
    assert_equal 4.25, gift_certificate.price, "price"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => ".25"))
    assert_equal 0.25, gift_certificate.price, "price"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => "$0.25"))
    assert_equal 0.25, gift_certificate.price, "price"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => "4"))
    assert_equal 4, gift_certificate.price, "price"
  end
  
  def test_allow_dollar_signs_in_value
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => 0.10, :value => "$4") )
    assert_equal 4.00, gift_certificate.value, "value"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => 0.10, :value => "  $4.25  "))
    assert_equal 4.25, gift_certificate.value, "value"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => 0.10, :value => "4.25") )
    assert_equal 4.25, gift_certificate.value, "value"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => 0.10, :value => ".25"))
    assert_equal 0.25, gift_certificate.value, "value"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => 0.10, :value => "$0.25"))
    assert_equal 0.25, gift_certificate.value, "value"

    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:price => 0.10, :value => "4"))
    assert_equal 4, gift_certificate.value, "value"
  end
  
  def test_terms_with_expiration
    gift_certificate = GiftCertificate.new(@valid_attributes.merge(:terms => nil, :expires_on => nil))
    assert_equal "", gift_certificate.terms_with_expiration
    gift_certificate.terms = "  Must bring ID  "
    assert_equal "Must bring ID.", gift_certificate.terms_with_expiration
    gift_certificate.terms = "  Must bring ID.  "
    assert_equal "Must bring ID.", gift_certificate.terms_with_expiration
    gift_certificate.expires_on = Date.new(2010, 2, 28).end_of_day
    assert_equal "Must bring ID. Expires 02/28/2010.", gift_certificate.terms_with_expiration
    gift_certificate.terms = ""
    assert_equal "Expires 02/28/2010.", gift_certificate.terms_with_expiration
  end
  
  def test_impression_counting
    time = Date.today.beginning_of_day
    (expectation = Time.stubs(:now)).returns(time)
    
    gift_certificate = GiftCertificate.create!(@valid_attributes)
    assert_equal 0, gift_certificate.impressions
    gift_certificate.record_impression
    assert_equal 1, gift_certificate.impressions
    assert_equal 1, gift_certificate.impression_counts.count
    
    expectation.returns(time + 1.hour)
    3.times { gift_certificate.record_impression }
    assert_equal 4, gift_certificate.impressions
    assert_equal 1, gift_certificate.impression_counts.count

    expectation.returns(time + 1.day)
    2.times { gift_certificate.record_impression }
    assert_equal 6, gift_certificate.impressions
    assert_equal 2, gift_certificate.impression_counts.count
  end
  
  def test_click_counting
    time = Date.today.beginning_of_day
    (expectation = Time.stubs(:now)).returns(time)
    
    gift_certificate = GiftCertificate.create!(@valid_attributes)
    assert_equal 0, gift_certificate.clicks
    gift_certificate.record_click
    assert_equal 1, gift_certificate.clicks
    assert_equal 1, gift_certificate.click_counts.count

    gift_certificate.record_click "twitter"
    assert_equal 2, gift_certificate.clicks
    assert_equal 2, gift_certificate.click_counts.count
    
    gift_certificate.record_click "facebook"
    assert_equal 3, gift_certificate.clicks
    assert_equal 3, gift_certificate.click_counts.count
    
    expectation.returns(time + 1.hour)
    2.times { gift_certificate.record_click }
    4.times { gift_certificate.record_click "twitter" }
    8.times { gift_certificate.record_click "facebook" }
    assert_equal 17, gift_certificate.clicks
    assert_equal 3, gift_certificate.click_counts.count

    expectation.returns(time + 1.day)
    2.times { gift_certificate.record_click "twitter" }
    4.times { gift_certificate.record_click "facebook" }
    assert_equal 23, gift_certificate.clicks
    assert_equal 5, gift_certificate.click_counts.count
  end

  def test_address_required
    assert Factory(:gift_certificate).valid?

    cert = Factory.build(:gift_certificate, :physical_gift_certificate => false, :collect_address => false)
    assert_equal false, cert.address_required?

    cert = Factory.build(:gift_certificate, :physical_gift_certificate => true, :collect_address => false)
    assert_equal true, cert.address_required?, "address is required for physical deal certificates"

    cert = Factory.build(:gift_certificate, :physical_gift_certificate => false, :collect_address => true)
    assert_equal true, cert.address_required?, "address is required when collecting addresses"
  end
  
  def test_humanize_price_currency_code_display
    gift_certificate = Factory :gift_certificate, :price => 11, :value => 27
    assert_equal "USD", gift_certificate.publisher.currency_code
    assert_equal "$11.00", gift_certificate.humanize_price
    
    gift_certificate.publisher.update_attributes :currency_code => "GBP"
    assert_equal "£11.00", gift_certificate.humanize_price
    
    gift_certificate.publisher.update_attributes :currency_code => "CAD"
    assert_equal "C$11.00", gift_certificate.humanize_price
  end

  def test_humanize_value_currency_code_display
    gift_certificate = Factory :gift_certificate, :price => 11, :value => 27
    assert_equal "USD", gift_certificate.publisher.currency_code
    assert_equal "$27.00", gift_certificate.humanize_value
    
    gift_certificate.publisher.update_attributes :currency_code => "GBP"
    assert_equal "£27.00", gift_certificate.humanize_value
    
    gift_certificate.publisher.update_attributes :currency_code => "CAD"
    assert_equal "C$27.00", gift_certificate.humanize_value
  end
  
  def test_item_name_currency_code_display
    gift_certificate = Factory :gift_certificate, :price => 11, :value => 27
    gift_certificate.advertiser.update_attributes :name => "test advertiser"
    assert_equal "USD", gift_certificate.publisher.currency_code
    assert_equal "$27.00 test advertiser Deal Certificate", gift_certificate.item_name
    
    gift_certificate.publisher.update_attributes :currency_code => "GBP"
    assert_equal "£27.00 test advertiser Deal Certificate", gift_certificate.item_name
    
    gift_certificate.publisher.update_attributes :currency_code => "CAD"
    assert_equal "C$27.00 test advertiser Deal Certificate", gift_certificate.item_name
  end
  
  def test_title_currency_code_display
    gift_certificate = Factory :gift_certificate, :price => 11, :value => 27
    gift_certificate.advertiser.update_attributes :name => "test advertiser"
    assert_equal "USD", gift_certificate.publisher.currency_code
    assert_equal "$27.00 Deal Certificate To test advertiser", gift_certificate.send(:title)
    
    gift_certificate.publisher.update_attributes :currency_code => "GBP"
    assert_equal "£27.00 Deal Certificate To test advertiser", gift_certificate.send(:title)
    
    gift_certificate.publisher.update_attributes :currency_code => "CAD"
    assert_equal "C$27.00 Deal Certificate To test advertiser", gift_certificate.send(:title)
  end

  def test_facebook_title_suffix
    gift_certificate = Factory(:gift_certificate, :message => "test")
    assert_equal "[#{gift_certificate.publisher.brand_name_or_name} Coupon] test", gift_certificate.facebook_title
    gift_certificate.facebook_title_suffix = "Deal Certificate"
    assert_equal "[#{gift_certificate.publisher.brand_name_or_name} Deal Certificate] test", gift_certificate.facebook_title
  end

  def test_facebook_url
    gift_certificate = Factory(:gift_certificate)

    gift_certificate.facebook_title_suffix = "Deal Certificate"
    
    title   = CGI.escape(gift_certificate.facebook_title)
    summary = CGI.escape(gift_certificate.description)
    image   = CGI.escape(gift_certificate.logo.url)

    assert_equal "http://www.facebook.com/share.php?s=100&p%5Burl%5D=gc.com&p%5Btitle%5D=#{title}&p%5Bsummary%5D=#{summary}&p%5Bimages%5D%5B0%5D=#{image}", gift_certificate.facebook_url("gc.com", false)
  end

  private
  
  def assign_valid_attributes
    @valid_attributes = { 
      :advertiser => advertisers(:changos), 
      :message => "this is the message",
      :value => 40.00,
      :price => 19.99,
      :number_allocated => 10
    }
  end
  
  def assert_invalid_attr_value(attr, value)
    gift_certificate = GiftCertificate.new(@valid_attributes.merge(attr => value))
    assert gift_certificate.invalid?, "Should not be valid with #{attr} of #{value}"
    assert gift_certificate.errors.on(attr), "Should have error on #{attr} with value #{value}"
  end
  
  def purchase(gift_certificate, quantity)
    count = gift_certificate.purchased_gift_certificates(true).count
    quantity.times do |i|
      gift_certificate.purchased_gift_certificates.create!({
        :paypal_payment_date => "14:18:05 Jan 14, 2010 PST",
        :paypal_txn_id => "38D93468JC716663#{count + i}",
        :paypal_receipt_id => "3625-4706-3930-068#{count + i}",
        :paypal_invoice => "12345678#{count + i}",
        :paypal_payment_gross => "%.2f" % gift_certificate.price,
        :paypal_payer_email => "higgins@london.com",
        :paypal_address_name => "Henry Higgins",
        :paypal_first_name => "Henry",
        :paypal_last_name => "Higgins",
        :paypal_address_street => "1 Penny Lane",
        :paypal_address_city =>"London",
        :paypal_address_state => "KY",
        :paypal_address_zip => "40742",
        :payment_status => "completed",
        :payment_status_updated_at => Time.zone.now,
        :payment_status_updated_by_txn_id => "38D93468JC7166634"
      })
    end
  end
end

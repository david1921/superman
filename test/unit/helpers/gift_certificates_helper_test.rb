require File.dirname(__FILE__) + "/../../test_helper"

class GiftCertificatesHelperTest < ActionView::TestCase
  
  def setup
    assign_valid_attributes
    GiftCertificateMailer.expects(:deliver_gift_certificate).at_least(0).returns(nil)
  end

  def test_render_sale_opens_at_with_nil_gift_certificate
    assert_equal "", render_sale_opens_at(nil)
  end
  
  def test_render_sale_opens_at_with_nil_gift_certificate_show_on_time
    gift_certificate = GiftCertificate.create!(@valid_attributes.except(:show_on))
    assert_nil gift_certificate.show_on
    assert_equal "", render_sale_opens_at(gift_certificate)
  end
  
  def test_render_sale_opens_at_with_gift_certificate_show_on_time_of_noon
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:show_on => Time.parse("03/12/2010 12:00:00 PST")))
    assert_not_nil gift_certificate.show_on
    assert_equal "Sale opens Friday at noon", render_sale_opens_at(gift_certificate)
  end
  
  def test_render_sale_opens_at_with_gift_certificate_show_on_time_of_one_pm
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:show_on => Time.parse("03/12/2010 13:00:00 PST")))
    assert_not_nil gift_certificate.show_on
    assert_equal "Sale opens Friday at 1pm", render_sale_opens_at(gift_certificate)
  end
  
  def test_render_sale_opens_at_with_gift_certificate_show_on_time_of_10_am
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:show_on => Time.parse("03/12/2010 10:00:00 PST")))
    assert_not_nil gift_certificate.show_on
    assert_equal "Sale opens Friday at 10am", render_sale_opens_at(gift_certificate)
  end
      
  def test_render_sale_opens_at_with_gift_certificate_show_on_time_of_midnight
    gift_certificate = GiftCertificate.create!(@valid_attributes.merge(:show_on => Time.parse("03/12/2010 00:00:00 PST")))
    assert_not_nil gift_certificate.show_on
    assert_equal "Sale opens Friday at 12am", render_sale_opens_at(gift_certificate)
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

end
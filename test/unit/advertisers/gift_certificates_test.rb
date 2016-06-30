require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::GiftCertificatesTest
class Advertisers::GiftCertificatesTest < ActiveSupport::TestCase
  def setup
    AppConfig.expects(:default_voice_response_code).at_most_once.returns(nil)
  end
  
  def test_gift_certificates_with_no_gift_certificates_associated_with_advertiser
    gift_certificate = GiftCertificate.create( :message => "My Certificate", :price => 10.00 )
    advertiser = advertisers(:changos)
    assert_equal 0, advertiser.gift_certificates.size
    assert_equal 0, advertiser.gift_certificates.available.size
  end

  def test_gift_certificates_with_one_gift_certificate_associated_with_advertiser_with_number_allocated_set_to_1
    advertiser = advertisers(:changos)
    gift_certificate = advertiser.gift_certificates.create( :message => "My Certificate", :price => 2.00, :value => 4.00, :number_allocated => 1 )
    advertiser = Advertiser.find( advertiser.id )
    assert_equal 1, gift_certificate.number_allocated
    assert_equal 1, advertiser.gift_certificates.size
    assert_equal 1, advertiser.gift_certificates.available.size
  end

  def gift_certificates_with_one_gift_certificate_associated_with_advertiser_with_number_allocated_set_to_0
    advertiser = advertisers(:changos)
    gift_certificate = advertiser.gift_certificates.create!( :message => "My Certificate", :price => 2.00, :value => 4.00, :number_allocated => 0 )
    advertiser = Advertiser.find( advertiser.id )
    assert_equal 0, gift_certificate.number_allocated
    assert_equal 1, advertiser.gift_certificates.size
    assert_equal 0, advertiser.gift_certificates.available.size
  end
end

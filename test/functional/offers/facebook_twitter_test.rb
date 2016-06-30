require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::FacebookTwitterTest < ActionController::TestCase
  tests OffersController

  def test_facebook_redirect_without_popup
    offer = offers(:changos_buy_two_tacos)
    offer.update_attributes! :message => "20% off two tacos"
    publisher = publishers(:sdh_boulder)
    assert_not_equal publisher, offer.publisher, "Offer should not belong to publisher"
    ClickCount.destroy_all
    time = Time.parse("Nov 23, 2008 12:34:56 UTC")
    Time.expects(:now).at_least_once.returns(time)

    timestamp = time.to_i

    get :facebook, :id => offer.to_param, :publisher_id => publisher.to_param

    offer_url = public_offers_url(publisher, :offer_id => offer.to_param, :v => offer.updated_at.to_i)
    escaped_t = "%5BStudent+Discount+Handbook+Boulder+Coupon%5D+20%25+off+two+tacos"
    assert_redirected_to %Q{http://www.facebook.com/share.php?u=#{CGI.escape(offer_url)}&t=#{escaped_t}}

    assert_equal 1, ClickCount.count, "Should generate one click count"
    click_count = ClickCount.first
    assert_equal offer, click_count.clickable, "Click-count offer"
    assert_equal Time.parse("Nov 23, 2008 00:00:00 UTC"), click_count.created_at, "Click-count create timestamp"
    assert_equal 1, click_count.count, "Click-count count"
    assert_equal "facebook", click_count.mode, "Click-count mode"
  end

  def test_facebook_redirect_with_popup
    offer = offers(:changos_buy_two_tacos)
    offer.update_attributes! :message => "20% off two tacos"
    publisher = publishers(:sdh_boulder)
    assert_not_equal publisher, offer.publisher, "Offer should not belong to publisher"
    ClickCount.destroy_all
    time = Time.parse("Nov 23, 2008 12:34:56 UTC")
    Time.expects(:now).at_least_once.returns(time)

    get :facebook, :id => offer.to_param, :publisher_id => publisher.to_param, :popup => true

    offer_url = public_offers_url(publisher, :offer_id => offer.to_param, :v => offer.updated_at.to_i)
    escaped_t = "%5BStudent+Discount+Handbook+Boulder+Coupon%5D+20%25+off+two+tacos"
    assert_redirected_to %Q{http://www.facebook.com/sharer.php?u=#{CGI.escape(offer_url)}&t=#{escaped_t}}

    assert_equal 1, ClickCount.count, "Should generate one click count"
    click_count = ClickCount.first
    assert_equal offer, click_count.clickable, "Click-count offer"
    assert_equal Time.parse("Nov 23, 2008 00:00:00 UTC"), click_count.created_at, "Click-count create timestamp"
    assert_equal 1, click_count.count, "Click-count count"
    assert_equal "facebook", click_count.mode, "Click-count mode"
  end

  def test_facebook_with_production_host_and_use_production_host_for_facebook_shares_set_to_true
    offer = offers(:changos_buy_two_tacos)
    offer.update_attributes! :message => "20% off two tacos"
    publisher = publishers(:sdh_boulder)
    publisher.update_attribute(:use_production_host_for_facebook_shares, true)
    assert_not_equal publisher, offer.publisher, "Offer should not belong to publisher"
    assert publisher.use_production_host_for_facebook_shares

    ClickCount.destroy_all
    time = Time.parse("Nov 23, 2008 12:34:56 UTC")
    Time.expects(:now).at_least_once.returns(time)

    host = "coupons.sdhboulder.com"
    Publisher.any_instance.stubs(:production_host).returns(host)

    get :facebook, :id => offer.to_param, :publisher_id => publisher.to_param, :popup => true

    offer_url = public_offers_url(publisher, :offer_id => offer.to_param, :v => offer.updated_at.to_i, :host => host)
    escaped_t = "%5BStudent+Discount+Handbook+Boulder+Coupon%5D+20%25+off+two+tacos"
    assert_redirected_to %Q{http://www.facebook.com/sharer.php?u=#{CGI.escape(offer_url)}&t=#{escaped_t}}

    assert_equal 1, ClickCount.count, "Should generate one click count"
    click_count = ClickCount.first
    assert_equal offer, click_count.clickable, "Click-count offer"
    assert_equal Time.parse("Nov 23, 2008 00:00:00 UTC"), click_count.created_at, "Click-count create timestamp"
    assert_equal 1, click_count.count, "Click-count count"
    assert_equal "facebook", click_count.mode, "Click-count mode"
  end

  def test_facebook_with_production_host_and_use_production_host_for_facebook_shares_set_to_false
    offer = offers(:changos_buy_two_tacos)
    offer.update_attributes! :message => "20% off two tacos"
    publisher = publishers(:sdh_boulder)
    assert_not_equal publisher, offer.publisher, "Offer should not belong to publisher"
    assert !publisher.use_production_host_for_facebook_shares

    ClickCount.destroy_all
    time = Time.parse("Nov 23, 2008 12:34:56 UTC")
    Time.expects(:now).at_least_once.returns(time)

    host = "coupons.sdhboulder.com"
    Publisher.any_instance.stubs(:production_host).returns(host)

    get :facebook, :id => offer.to_param, :publisher_id => publisher.to_param, :popup => true

    offer_url = public_offers_url(publisher, :offer_id => offer.to_param, :v => offer.updated_at.to_i)
    escaped_t = "%5BStudent+Discount+Handbook+Boulder+Coupon%5D+20%25+off+two+tacos"
    assert_redirected_to %Q{http://www.facebook.com/sharer.php?u=#{CGI.escape(offer_url)}&t=#{escaped_t}}

    assert_equal 1, ClickCount.count, "Should generate one click count"
    click_count = ClickCount.first
    assert_equal offer, click_count.clickable, "Click-count offer"
    assert_equal Time.parse("Nov 23, 2008 00:00:00 UTC"), click_count.created_at, "Click-count create timestamp"
    assert_equal 1, click_count.count, "Click-count count"
    assert_equal "facebook", click_count.mode, "Click-count mode"
  end

  def test_twitter_redirect
    offer = offers(:changos_buy_two_tacos)
    offer.update_attributes! :message => "20% off two tacos"
    publisher = publishers(:sdh_boulder)
    assert_not_equal publisher, offer.publisher, "Offer should not belong to publisher"
    ClickCount.destroy_all
    time = Time.parse("Nov 23, 2008 12:34:56 UTC")
    Time.expects(:now).at_least_once.returns(time)

    get :twitter, :id => offer.to_param, :publisher_id => publisher.to_param

    escaped_status = CGI.escape("[Student Discount Handbook Boulder Coupon] 20% off two tacos at Changos - http://bit.ly/56256").gsub('+', '%20')
    assert_redirected_to %Q{http://twitter.com/?status=#{escaped_status}}

    assert_equal 1, ClickCount.count, "Should generate one click count"
    click_count = ClickCount.first
    assert_equal offer, click_count.clickable, "Click-count offer"
    assert_equal Time.parse("Nov 23, 2008 00:00:00 UTC"), click_count.created_at, "Click-count create timestamp"
    assert_equal 1, click_count.count, "Click-count count"
    assert_equal "twitter", click_count.mode, "Click-count mode"
  end

  def test_twitter_redirect_with_brand_twitter_prefix_set_for_publisher
    offer = offers(:changos_buy_two_tacos)
    offer.update_attributes! :message => "20% off two tacos"

    publisher = publishers(:sdh_boulder)
    assert_not_equal publisher, offer.publisher, "Offer should not belong to publisher"
    publisher.update_attribute( :brand_twitter_prefix, "Coupon from @mySDH:" )

    get :twitter, :id => offer.to_param, :publisher_id => publisher.to_param

    escaped_status = CGI.escape("Coupon from @mySDH: 20% off two tacos at Changos - http://bit.ly/56256").gsub('+', '%20')
    assert_redirected_to %Q{http://twitter.com/?status=#{escaped_status}}
  end


  test "facebook when publisher has a path format configured" do
    publishing_group = Factory(:publishing_group, :label => "mcclatchy")
    publisher = Factory(:publisher, {
      :label => "sacbee",
      :name => "Sacramento Bee",
      :publishing_group => publishing_group,
      :production_host => "sacbee.findnsave.com",
      :use_production_host_for_facebook_shares => true
    })
    advertiser = Factory(:advertiser, :publisher => publisher)
    offer = Factory(:offer, :advertiser => advertiser)

    get :facebook, :id => offer.to_param, :publisher_id => publisher.to_param, :popup => true

    offer_url = "http://sacbee.findnsave.com/Coupons?couponid=#{offer.id}&v=#{offer.updated_at.to_i}"
    escaped_t = "%5BSacramento+Bee+Coupon%5D+this+is+a+message"
    assert_redirected_to "http://www.facebook.com/sharer.php?u=#{CGI.escape(offer_url)}&t=#{escaped_t}"
  end

end

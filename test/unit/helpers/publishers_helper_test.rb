require File.dirname(__FILE__) + "/../../test_helper"

class PublishersHelperTest < ActionView::TestCase

  test "affiliated_deals_for" do
    daily_deal = Factory :daily_deal, :value_proposition => "the best deal ever"
    affiliated_pub = Factory :publisher, :label => "some-affiliate"

    assert_equal "No affiliated deals", affiliated_deals_for(affiliated_pub)
    Factory :affiliate_placement, :affiliate => affiliated_pub, :placeable => daily_deal
    affiliated_deals_ul = affiliated_deals_for(affiliated_pub.reload)
    assert_match /<ul class="affiliated-deals">/, affiliated_deals_ul
    assert_match %r{<div class="value-prop"><a href="/daily_deals/\d+/edit">the best deal ever</a></div>}, affiliated_deals_ul
    assert_match %r{<div class="publisher">from <a href="/publishers/\d+/edit">some-affiliate</a></div>}, affiliated_deals_ul
  end
  
  test "zip code label" do
    publisher = Factory(:publisher)
    assert_equal "ZIP Code", zip_code_label(publisher)

    publisher = Factory(:gbp_publisher)
    assert_equal "Postcode", zip_code_label(publisher)

    publisher = Factory(:cad_publisher)
    assert_equal "Postal Code", zip_code_label(publisher)
  end

end
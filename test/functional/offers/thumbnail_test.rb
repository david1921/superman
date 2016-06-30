require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::ThumbnailTest < ActionController::TestCase
  tests OffersController

  def test_thumbnail_with_no_offers
    publisher   = publishers(:houston_press)
    publisher.update_attribute(:production_host, "coupons.houstonpress.com")
    advertiser  = publisher.advertisers.create!(:name => "Joe's automotive", :listing => "mylisting")

    get :thumbnail, :label => publisher.label

    assert_response :success
    assert_layout   false
    assert_equal    "businessdirectory", publisher.theme
    assert_template "offers/businessdirectory/thumbnail"
    assert assigns(:offers).empty?
    assert assigns(:categories).empty?

    assert_select "div#analog_analytics_content" do
      assert_select "h2", :text => "Find A Coupon"
      assert_select "div#thumbnail_search" do
        assert_select "form[action='http://coupons.houstonpress.com/houston/deals/'][method='get']"
        assert_select "select[name='category_id']", false
        assert_select "input[type='text'][name='postal_code'][value='']"
        assert_select "input[type='text'][name='text'][value='']"
        assert_select "button[type='submit']", :text => "Search"
      end
      assert_select "div#thumbnail_offers" do
        assert_select "h3", :text => "Popular Coupons"
        assert_select "p", :text => "Sorry, there are no popular coupons at this time."
      end
      assert_select "a[href='http://coupons.houstonpress.com/houston/deals/'][class='more']", :html => "More Popular Coupons &raquo;"
    end
  end

  def test_thumbnail_with_two_offers
    publisher   = publishers(:houston_press)
    publisher.update_attribute(:production_host, "coupons.houstonpress.com")
    advertiser  = publisher.advertisers.create!(:name => "Joe's automotive", :listing => "mylisting")

    offer_1       = advertiser.offers.create!( :message => "first offer", :category_names => "Retail" )
    offer_2       = advertiser.offers.create!( :message => "second offer", :category_names => "Cars : Detailing" )

    get :thumbnail, :label => publisher.label

    assert_response :success
    assert_layout   false
    assert_equal    "businessdirectory", publisher.theme
    assert_template "offers/businessdirectory/thumbnail"
    assert !assigns(:offers).empty?
    assert !assigns(:categories).empty?

    offers = assigns(:offers)
    assert_select "div#analog_analytics_content" do
      assert_select "h2", :text => "Find A Coupon"
      assert_select "div#thumbnail_search" do
        assert_select "form[action='http://coupons.houstonpress.com/houston/deals/'][method='get']"
        assert_select "select[name='category_id']"
        assert_select "input[type='text'][name='postal_code'][value='']"
        assert_select "input[type='text'][name='text'][value='']"
        assert_select "button[type='submit']", :text => "Search"
      end
      assert_select "div#thumbnail_offers" do
        assert_select "h3", :text => "Popular Coupons"
        assert_select "ul" do
          offers.each_with_index do |offer, index|
            assert_select "li:nth-child(#{index+1})" do
              assert_select "div.photo"
              assert_select "div.content" do
                assert_select "a[href='http://coupons.houstonpress.com/houston/deals/?offer_id=#{offer.id}']", :text => offer.value_proposition
                assert_select "div.advertiser", :text => offer.advertiser_name
              end
            end
          end

        end
      end
      assert_select "a[href='http://coupons.houstonpress.com/houston/deals/'][class='more']", :html => "More Popular Coupons &raquo;"
    end
  end
end

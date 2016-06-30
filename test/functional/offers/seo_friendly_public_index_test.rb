require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::SeoFriendlyPublicIndexTest < ActionController::TestCase
  tests OffersController

  def test_seo_friendly_with_no_path_information
    publisher = publishers(:sdcitybeat)
    get :seo_friendly_public_index, :publisher_label => publisher.label, :path => []

    assert_layout         "offers/sdcitybeat/public_index"
    assert_template       "offers/sdcitybeat/public_index"
    assert_not_nil         assigns(:publisher)
    assert_not_nil         assigns(:offers)
  end

  def test_seo_friendly_with_advertiser
    publisher   = publishers(:sdcitybeat)
    advertiser  = publisher.advertisers.create!(:name => "Joe's automotive", :listing => "mylisting")

    assert_equal "joes-automotive", advertiser.label
    assert_equal advertiser, publisher.advertisers.find_by_label( advertiser.label )

    get :seo_friendly_public_index, :publisher_label => publisher.label, :advertiser_label => advertiser.label

    assert_layout         "offers/sdcitybeat/public_index"
    assert_template       "offers/sdcitybeat/public_index"
    assert_not_nil         assigns(:publisher)
    assert_not_nil         assigns(:advertiser)
    assert_not_nil         assigns(:offers)
  end

  def test_seo_friendly_with_parent_category
    publisher   = publishers(:sdcitybeat)
    advertiser  = publisher.advertisers.create!(:name => "Joe's automotive", :listing => "mylisting")
    offer       = advertiser.offers.create!( :message => "my message", :category_names => "Cars : Detailing" )

    cars_category = offer.categories.find_by_name("Cars")
    assert_not_nil cars_category

    get :seo_friendly_public_index, :publisher_label => publisher.label, :path => ["cars"]

    assert_layout         "offers/sdcitybeat/public_index"
    assert_template       "offers/sdcitybeat/public_index"
    assert_not_nil         assigns(:publisher)
    assert_equal           cars_category, assigns(:category)
    assert_not_nil         assigns(:offers)
  end

  def test_seo_friendly_with_child_category
    publisher   = publishers(:houston_press)
    publisher.update_attribute(:production_host, "coupons.houstonpress.com")
    advertiser  = publisher.advertisers.create!(:name => "Joe's automotive", :listing => "mylisting")

    10.times {|i| advertiser.offers.create!( :message => "my message #{i}", :category_names => "Cars : Detailing" ) }

    get :seo_friendly_public_index, :publisher_label => publisher.label, :path => ["detailing"]

    assert_layout         "offers/public_index"
    assert_template       "businessdirectory/public_index"
    assert_not_nil         assigns(:publisher)
    assert_not_nil         assigns(:category)
    assert_not_nil         assigns(:offers)

    assert_select ".navigation .top" do
      assert_select "select[name='page_size']" do
        assert_select "option[value='4'][selected='selected']", :text => "4"
        assert_select "option[value='10']", :text => "10"
        assert_select "option[value='20']", :text => "20"
        assert_select "option[value='50']", :text => "50"
        assert_select "option[value='100']", false
      end
    end
    assert_select ".navigation .bottom" do
      assert_select "ul.pagination" do
        assert_select "li:nth-child(1)", :text => "1"
        assert_select "li:nth-child(2)", :text => "2" do
          assert_select "a[href='http://coupons.houstonpress.com/houston/deals/cars/detailing/?page=2&amp;page_size=4']"
        end
        assert_select "li:nth-child(3)", :text => "3" do
          assert_select "a[href='http://coupons.houstonpress.com/houston/deals/cars/detailing/?page=3&amp;page_size=4']"
        end
      end
    end
  end

  def test_seo_friendly_with_wgs84_format
    publisher  = Factory(:publisher, :label => 'sfweekly', :advertiser_has_listing => true, :name => 'publisher')
    logo       = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/burger_king.png", 'image/png')
    advertiser = Factory(:advertiser, :publisher => publisher, :logo => logo, :listing => 'mylisting')
    2.times { Factory(:offer, :advertiser => advertiser) }

    get :seo_friendly_public_index, :publisher_label => publisher.label, :format => "wgs84"

    assert_response   :success
    assert_not_nil    assigns(:publisher)
    assert_not_nil    assigns(:offers)
    assert !@response.body["http://http"], "Should add http protocol and host only once"
    assert !@response.body["http://test.host:80"], "should not attache port of 80"

    assert_equal "application/xml", @response.content_type
    root = Nokogiri.parse(@response.body)
    assert_equal "Coupons For publisher", root.xpath('/rss/channel/title').text
    assert_match %r{http://s3.amazonaws.com/logos.advertisers.analoganalytics.com/test/#{advertiser.id}/standard.png\?\d+}, root.xpath('/rss/channel/item/image_url').text
    assert_equal 2, root.xpath('/rss/channel/item').size, "Should have 2 items (offers)"
  end

  def test_seo_friendly_with_a_postal_code_length_larger_than_9
    publisher   = publishers(:houston_press)
    get :seo_friendly_public_index, :publisher_label => publisher.label, :postal_code => "1234567890"
    assert_response :not_found
  end

  def test_seo_friendly_with_postal_code_parameter
    publisher   = publishers(:houston_press)
    get :seo_friendly_public_index, :publisher_label => publisher.label, :postal_code => "97206"
    assert_response :success
  end
end

require File.dirname(__FILE__) + "/../../test_helper"

class CouponsHelperTest < ActionView::TestCase
  def test_public_index_notice_in_demo
    Rails.expects(:env).returns("demo")
    assert_notice_div(/not redeemable/i, public_index_notice(publishers(:my_space)))
  end

  def test_public_index_notice_for_sdnn
    publisher = Factory(:publisher, :name => "San Diego News Network")
    assert_notice_div(/try two months/i, public_index_notice(publisher))
  end

  def test_public_index_notice_for_other
    assert_equal "", public_index_notice(publishers(:my_space))
  end

  def test_iframe_height_and_width
    @publisher = Publisher.new
    assert_equal 750, iframe_height(4), "Default layout iframe_height"
    assert_equal 936, iframe_width, "Default layout iframe_width"

    @publisher = Publisher.new(:theme => "enhanced")
    assert_equal 1490, iframe_height(4), "Default layout iframe_height"
    assert_equal 936, iframe_width, "Default layout iframe_width"

    @publisher = Publisher.new(:theme => "narrow")
    assert_equal 750, iframe_height(4), "Default layout iframe_height"
    assert_equal 625, iframe_width, "Default layout iframe_width"

    @publisher = Publisher.new
    assert_equal 446, iframe_height(3), "Default layout iframe_height"
    assert_equal 936, iframe_width, "Default layout iframe_width"

    @publisher = Publisher.new(:theme => "enhanced")
    assert_equal 1154, iframe_height(3), "Default layout iframe_height"
    assert_equal 936, iframe_width, "Default layout iframe_width"

    @publisher = Publisher.new(:theme => "narrow")
    assert_equal 446, iframe_height(3), "Default layout iframe_height"
    assert_equal 625, iframe_width, "Default layout iframe_width"

    @publisher = Publisher.new(:theme => "standard")
    assert_equal 900, iframe_height(4), "Default layout iframe_height"
    assert_equal 936, iframe_width, "Default layout iframe_width"
  end
  
  def test_advertiser_name
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:my_space) 
    assert_dom_equal "BURGER KING", advertiser_name(offer), "Simple format, no website"
    
    offer.advertiser(true).website_url = "http://drunkcyclist.com"
    assert_dom_equal "<a href='http://drunkcyclist.com' target='_blank'>BURGER KING</a>", advertiser_name(offer), "Simple format, website"
        
    publisher.label = "the-hour"
    publisher.save!
    offer.publisher(true)
    offer.advertiser(true).website_url = nil
    assert_dom_equal "BURGER KING", advertiser_name(offer), "Enhanced layout, no website"
    
    offer.advertiser(true).website_url = "http://drunkcyclist.com"
    assert_dom_equal "<a href='http://drunkcyclist.com' target='_blank'>BURGER KING</a>", advertiser_name(offer), "Enhanced layout, website"
  end
  
  def test_advertiser_name_with_standard_theme
    publisher = publishers( :sdreader )
    offer     = publisher.advertisers.create!( :name => "Burger King" ).offers.create!(:message => 'hello')
    assert_dom_equal "Burger King", advertiser_name(offer), "SD Reader, no website"
  end
  
  def test_advertiser_name_honors_publisher_preferences
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:my_space)
    publisher.link_to_website = false
    publisher.save!
    assert_dom_equal "BURGER KING", advertiser_name(offer), "Simple format, no website"
    
    offer.advertiser(true).website_url = "http://drunkcyclist.com"
    assert_dom_equal "BURGER KING", advertiser_name(offer), "Simple format, website"

    publisher.link_to_website = true
    publisher.save!
    offer.advertiser(true).website_url = "http://drunkcyclist.com"
    offer.publisher(true)
    assert_dom_equal "<a href='http://drunkcyclist.com' target='_blank'>BURGER KING</a>", advertiser_name(offer), "Simple layout, website"
    
    offer.website = nil
    offer.advertiser(true)
    offer.advertiser.website_url = nil
    assert_dom_equal "BURGER KING", advertiser_name(offer), "Simple layout, website"
  end
  
  def test_link_to_website
    offer = offers(:my_space_burger_king_free_fries)
    offer.publisher.link_to_website = false
    assert_equal nil, link_to_website(offer), "Simple format, no website"
    
    offer.advertiser.website_url = "http://drunkcyclist.com"
    assert_equal nil, link_to_website(offer), "Simple format, website"

    offer.publisher.link_to_website = true
    offer.advertiser.website_url = nil
    assert_nil link_to_website(offer), "Simple layout, website"

    offer.website = "http://drunkcyclist.com"
    offer.advertiser.website_url = "http://drunkcyclist.com"
    assert_dom_equal "<a href='http://drunkcyclist.com' target='_blank'>Website</a>", link_to_website(offer), "Simple layout, website"

    offer.advertiser.website_url = "drunkcyclist.com"
    assert offer.advertiser.valid?, "Advertiser validation"
    assert_dom_equal "<a href='http://drunkcyclist.com' target='_blank'>Website</a>", link_to_website(offer), "Simple layout, website"
  end
  
  def test_link_to_map
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:my_space)
    publisher.link_to_map = false
    assert_equal nil, link_to_map(offer), "no address, no map_url, no link_to_map"

    publisher.link_to_map = true
    assert_equal nil, link_to_map(offer), "no address, no map_url, link_to_map"

    offer.advertiser(true).google_map_url = ""
    assert_equal nil, link_to_map(offer), "no address, blank map_url, link_to_map"
    
    offer.advertiser(true).stores.create :address_line_1 => "123 Main Street", :city => "Mulberry", :state => "NC"
    offer.publisher.link_to_map = false
    assert_equal nil, link_to_map(offer), "address, blank map_url, no link_to_map"

    offer.publisher.link_to_map = true
    assert_match("http://maps.google.com/maps", link_to_map(offer), "address, blank map_url, link_to_map")
    assert_match("Map", link_to_map(offer), "address, blank map_url, no link_to_map")
    assert_match("123+Main+Street", link_to_map(offer), "address, blank map_url, no link_to_map")
    
    offer.advertiser(true).google_map_url = "http://www.example.com/"
    assert_match("http://www.example.com", link_to_map(offer), "no address, map_url, link_to_map")
    assert_match("Map", link_to_map(offer), "no address, map_url, link_to_map")
    
    offer.advertiser(true).stores.create :address_line_1 => "123 Main Street"
    offer.advertiser.google_map_url = "http://www.example.com/"
    assert_match("http://www.example.com", link_to_map(offer), "address, map_url, link_to_map")
    assert_match("Map", link_to_map(offer), "address, map_url, no link_to_map")
  end
  
  def test_map_image_url_for
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:my_space)
    publisher.link_to_map = true
    offer.advertiser(true).stores.create :address_line_1 => "633 SE Powell Blvd", :city => "Portland", :state => "OR", :zip => "97202"
    offer.advertiser(true).stores.create :address_line_1 => "633 SE Powell Blvd", :city => "Portland", :state => "OR", :zip => "97202"
    map_image_url = map_image_url_for(offer)
    assert_match("http://maps.google.com/maps/api/staticmap", map_image_url, "map_image_url_for host")
    assert map_image_url.include?("center=633+SE+Powell+Blvd%2C+Portland%2C+OR+97202"), "map_image_url_for center param"
    assert map_image_url.include?("markers=size:small|633+SE+Powell+Blvd%2C+Portland%2C+OR+97202"), "map_image_url_for markers"
    assert map_image_url.include?("sensor=false"), "map_image_url_for sensor"
    assert map_image_url.include?("key="), "map_image_url_for key"
  end

  def test_map_image_url_for_with_no_stores
    offer = Factory(:offer)
    offer.advertiser.stores.clear
    assert_equal "", map_image_url_for(offer)
  end
  
  def test_multi_loc_map_image_url_for
    advertiser = Factory(:advertiser)
    advertiser.stores.clear
    advertiser.stores << Factory(:store, :address_line_1 => "100 SE Powell Blvd", :city => "Portland", :state => "OR", :zip => "97202")
    advertiser.stores << Factory(:store, :address_line_1 => "309 Southwest Broadway", :city => "Portland", :state => "OR", :zip => "97205")
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)
    map_image_url = map_image_url_for(daily_deal, "100x100", true)
    assert_match %r{http://maps.google.com/maps/api/staticmap}, map_image_url, "multi loc map_image_url_for"
    assert_match %r{[^&]309\+Southwest\+Broadway%2C\+Portland%2C\+OR\+97205}, map_image_url, "multi loc map_image_url_for markers location 1"
    assert_match %r{markers=[^&]+100\+SE\+Powell\+Blvd%2C\+Portland%2C\+OR\+97202}, map_image_url, "multi loc map_image_url_for markers location 2"
  end
  
  def test_url_for_facebook_image
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:my_space)
    url = url_for_facebook_image(offer)
    assert_equal "http://test.host/images/missing/advertisers/logos/standard.png", url, "url_for_facebook_image"
    
    offer.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    offer.save!
    url = url_for_facebook_image(offer)
    assert url.include?("http://s3.amazonaws.com/photos.offers.analoganalytics.com/test/"), "url_for_facebook_image"
    assert url.include?("/standard.png"), "url_for_facebook_image"

    offer.offer_image = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    offer.save!
    url = url_for_facebook_image(offer)
    assert url.include?("offer-images.offers.analoganalytics.com/test/"), "url_for_facebook_image"
    assert url.include?("/medium.png"), "url_for_facebook_image"

    advertiser = offer.advertiser
    advertiser.logo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/burger_king.png", 'image/png')
    advertiser.save!
    assert_equal 130, advertiser.logo_facebook_width, "logo_facebook_width"
    assert_equal 110, advertiser.logo_facebook_height, "logo_facebook_height"
    assert advertiser.logo_dimension_valid_for_facebook?, "logo_dimension_valid_for_facebook?"

    url = url_for_facebook_image(offer)
    assert url.include?("http://s3.amazonaws.com/logos.advertisers.analoganalytics.com/test/"), "url_for_facebook_image"
    assert url.include?("/facebook.png"), "url_for_facebook_image"
  end

  def test_link_to_email
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:my_space)
    publisher.link_to_email = false
    assert_equal nil, link_to_email(offer), "no address, no link_to_email"

    publisher.link_to_email = true
    assert_equal nil, link_to_email(offer), "no address, link_to_email"

    publisher.link_to_email = false
    offer.advertiser(true).email_address = "steve@apple.com"
    assert_equal nil, link_to_map(offer), "no address, link_to_email"

    publisher.link_to_email = true
    offer.advertiser(true).email_address = "steve@apple.com"
    assert_match("mailto:steve@apple.com", link_to_email(offer), "address, link_to_email")
  end
  
  def test_link_to_advanced_search
    publisher = publishers(:sdreader)
    link = link_to_advanced_search("Coupons Home", publisher, nil, nil, nil, nil, nil, nil, nil, "iframe")
    assert_dom_equal "<a href='/publishers/sdreader?layout=iframe' target='_top'>Coupons Home</a>", link, "advanced search link"
  end
  
  def test_link_to_advanced_search_in_iframe
    publisher = publishers(:sdreader)
    link = link_to_advanced_search("Coupons Home", publisher, nil, nil, nil, nil, nil, nil, nil, "iframe")
    assert_dom_equal "<a href='/publishers/sdreader?layout=iframe' target='_top'>Coupons Home</a>", link, "advanced search link"
  end

  def test_link_to_advanced_search_link_target
    publisher = publishers(:sdreader)
    publisher.update_attribute(:advanced_search_link_target, "_parent")
    link = link_to_advanced_search("Coupons Home", publisher, nil, nil, nil, nil, nil, nil, nil, "iframe")
    assert_dom_equal "<a href='/publishers/sdreader?layout=iframe' target='_parent'>Coupons Home</a>", link, "advanced search link"
  end

  def test_link_to_advanced_search_no_link_target
    publisher = publishers(:sdreader)
    publisher.update_attribute(:advanced_search_link_target, nil)
    link = link_to_advanced_search("Coupons Home", publisher, nil, nil, nil, nil, nil, nil, nil, "iframe")
    assert_dom_equal "<a href='/publishers/sdreader?layout=iframe'>Coupons Home</a>", link, "advanced search link"
  end
  
  def test_missing_offer_photo_image_tag
    offer = offers(:changos_buy_two_tacos)
    expected = %Q(<img alt="photo" class="photo" id="offer_#{offer.id}_photo" src="http://test.host/images/missing/offers/photos/standard.png" />)
    assert_equal expected, offer_photo_image_tag(offer)
  end
  
  def test_offer_photo_image_tag
    offer = offers(:changos_buy_two_tacos)
    offer.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/burger_king.png", 'image/png')
    offer.save!
    expected = %r{<img alt="photo" class="photo" id="offer_#{offer.id}_photo" src="http://s3.amazonaws.com/photos.offers.analoganalytics.com/test/#{offer.id}/standard.png}
    assert_match expected, offer_photo_image_tag(offer)
  end

  def test_offer_logo_image_tag
    offer = offers(:changos_buy_two_tacos)
    expected = %Q(<img alt="logo" id="offer_#{offer.id}_logo" src="http://test.host/images/missing/advertisers/logos/standard.png" />)
    assert_equal expected, advertiser_logo_image_tag(offer)
  end

  private

  def assert_notice_div(regex, string)
    assert_not_nil((div = REXML::Document.new(string).elements["/div"]))
    assert_equal "notice", div.attributes["id"]
    assert_match regex, div.text
  end
end

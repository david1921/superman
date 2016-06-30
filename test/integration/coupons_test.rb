require File.dirname(__FILE__) + "/../test_helper"

class CouponsTest < ActionController::IntegrationTest
  assert_no_angle_brackets :except => :test_coupons_page_mockup

  def test_coupons_page_mockup
    publisher = publishers(:my_space)
    
    get coupons_page_path(:label => publisher.label)
    assert_response :success
    assert_layout nil
    # Ensure absolute path to JS
    assert_select "script[src=http://www.example.com/publishers/myspace/embed_coupons.js]"
    assert_select "noscript", /you must enable javascript/i
  end
  
  def test_embed_coupons
    publisher = publishers(:my_space)
    
    get embed_coupons_path(:label => publisher.label, :format => :js)
    assert_response :success
    assert_layout nil
  end
  
  def test_embed_coupon_by_label
    locm = publishers(:locm)
    offer = locm.advertisers.create!(:listing => "1234").offers.create!(:message => "buy more")
    offer.update_attribute :label, "109888X"
    get "/publishers/locm/coupons/#{offer.label}/show.js"
    assert_response :success
    assert_layout nil
    assert_match "document.write", @response.body
    assert_match "iframe", @response.body
    assert_match "/offers/#{offer.id}", @response.body
  end
  
  def test_embed_coupon_by_label_same_as_id
    locm = publishers(:locm)
    offer = locm.advertisers.create!(:listing => "1234").offers.create!(:message => "buy more")
    get "/publishers/locm/coupons/#{offer.id}/show.js"
    assert_response :success
    assert_layout nil
    assert_match "document.write", @response.body
    assert_match "iframe", @response.body
    assert_match "/offers/#{offer.id}", @response.body
  end
  
  def test_show
    locm = publishers(:locm)
    offer = locm.advertisers.create!(:listing => "1234").offers.create!(:message => "buy more")
    get "/offers/#{offer.id}"
    assert_response :success
    assert_layout "offers/show"
  end
  
  def test_public_pages_for_all_standard_publishers
    %w{ chicoer elpasotimes knoxville monthlygrapevine sdreader tucsonweekly vcreporter }.each do |label|
      publisher = Publisher.find_by_label(label)
      if publisher
        publisher.update_attribute!(:theme, "standard") unless publisher.theme == "standard"
      else
        publisher = Factory(:publisher, :name => label, :label => label, :theme => "standard")
      end
      
      get "/publishers/#{label}"
      assert_response :success, "Public landing page for #{label}"
      
      get "/publishers/#{publisher.id}/offers"
      assert_response :success, "Public offers page for #{label}"
    end
  end
  
  def test_public_index_routing
    assert_routing "/publishers/4/offers",     :controller => "offers", :action => "public_index", :publisher_id => "4"
    assert_routing "/publishers/4/offers.xml", :controller => "offers", :action => "public_index", :publisher_id => "4", :format => "xml"
  end

  def test_every_theme_should_have_facebook_metadata
    # There isn't a default "withtheme" setup at this time, so let's remove it from the themes test
    # "howlingwolfoptimized" theme is not an offers theme
    Publisher::THEMES.except("withtheme").keys.each do |theme|
      publisher = Publisher.find_by_label(theme) || 
                  Factory(:publisher, :name => "Publisher #{theme.titlecase}", :label => theme, :theme => theme, :show_facebook_button => true)
      offer = publisher.advertisers.create!(:name => "Bob's Red Mill", :tagline => "Old school grain").offers.create!(
        :message => "The message",
        :value_proposition => "$1000 off",
        :terms => "February only",
        :expires_on => "Nov 15, 2008"
      )
      
      get public_offers_path publisher, :offer_id => offer

      assert_select "meta[name=title][content=?]", "[#{publisher.name} Coupon] $1000 off", 1, "title metatag for publisher #{publisher.name}, #{theme}"

      assert_select "meta[name=description][content=?]", 
                    "Bob's Red Mill: Old school grain; The message; February only.", 1, 
                    "description metatag for publisher #{publisher.name}, #{theme}"
                    
      # assert_select "meta[name=og:image]", 3, "image link for publisher #{publisher.name}, #{theme}"
      #  how to rewrite this and line 131 to access :minimum => 1 and not a straight only one...
    end
  end

  def test_every_custom_template_should_have_facebook_metadata
    custom_layouts.each do |custom_layout|
      publisher = Publisher.find_by_label(custom_layout) || Factory(:publisher, 
        :name => "Publisher #{custom_layout.titlecase}",
        :label => custom_layout,
        :theme => "sdcitybeat",
        :show_facebook_button => true
      )

      offer = publisher.advertisers.create!(
                :name => "Bob's Red Mill", 
                :tagline => "Old school grain", 
                :listing => (publisher.advertiser_has_listing? ? "123" : nil),
                :description => "test description"
              ).offers.create!(
        :message => "The message",
        :value_proposition => "$1000 off",
        :terms => "February only",
        :expires_on => "Nov 15, 2008"
      )
      get public_offers_path publisher, :offer_id => offer
      quietly do
        assert_select "meta[name=title]", 1,
          "title metatag for publisher #{publisher.name}, #{custom_layout}"
        assert_select "meta[name=description]",  1, 
          "Should only have single description metatag for publisher #{publisher.name}, #{custom_layout} in:\n#{@response.body}"
        assert_select "meta[name=description][content=?]",  "Bob's Red Mill: Old school grain; The message; February only.", 1, 
          "description metatag for publisher #{publisher.name}, #{custom_layout}"
        # assert_select "meta[name=og:image]", 3, "image link for publisher #{publisher.name}, #{custom_layout}"
      end
    end
  end
  
  def test_wrong_method_from_coupon_actions
    offer = offers(:my_space_burger_king_free_fries)
    advertiser = offer.advertiser
    advertiser.coupon_clipping_modes = [ :email, :txt, :call ]
    advertiser.call_phone_number = "1 212 444 1010"
    advertiser.save!

    post "/advertisers/#{advertiser.to_param}/offers/#{offer.to_param}/txt"
    assert_response :success
    assert_template "advertisers/offers/txt"

    post "/advertisers/#{advertiser.to_param}/offers/#{offer.to_param}/email"
    assert_response :success
    assert_template "advertisers/offers/email"

    post "/offers/#{offer.to_param}/call?publisher_id=#{offer.publisher.to_param}"
    assert_response :success
    assert_template "offers/call"

    get "/advertisers/#{advertiser.to_param}/offers/#{offer.to_param}/txt"
    assert_response :success
    assert_template "offers/nofollow"

    get "/advertisers/#{advertiser.to_param}/offers/#{offer.to_param}/email"
    assert_response :success
    assert_template "offers/nofollow"

    get "/offers/#{offer.to_param}/call?publisher_id=#{offer.publisher.to_param}"
    assert_response :success
    assert_template "offers/nofollow"
  end   
  
  private
  
  def custom_layouts
    layout_root = "#{Rails.root}/app/views/layouts/offers"
    custom_layouts = Dir.new(layout_root).select do |dir_name|
      dir_name != "." && File.directory?("#{layout_root}/#{dir_name}") && File.exists?("#{layout_root}/#{dir_name}/public_index.html.erb")
    end
  end
  
end

require File.dirname(__FILE__) + "/../test_helper"

class OffersControllerTest < ActionController::TestCase  
    
  def test_destroy
    advertiser = advertisers(:changos)
    offer = advertiser.offers.create!(:message => "Free yogurt with your taco")
    check_response = lambda { |role|
      assert_redirected_to edit_advertiser_path(advertiser), role
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      delete :destroy, :id => offer.to_param, :advertiser_id => advertiser.to_param
    end
    assert Offer.exists?(offer.id), "Should not delete offer, just mark it as deleted"
    assert offer.reload.deleted?, "Offer deleted?"
  end
  
  def test_clear_photo_invalid_offer
    offer = offers(:my_space_burger_king_free_fries)
    offer.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    offer.save!
    
    # Bypass validation
    offer.txt_message = "Message with bad chars: •ªº"
    offer.save(false)
    offer.reload
    assert_equal "Message with bad chars: •ªº", offer.txt_message, "txt_message"
    assert !offer.valid?, "Offers should not be valid with bad TXT characters"
    
    @request.session[:user_id] = users(:aaron)
    xhr :post, :clear_photo, :id => offer.to_param
    assert_response :success

    assert @response.body.include?("Txt message contains one or more disallowed characters"), 
      "Expected error message in #{@response.body}"

    # Get latest attachment state from DB
    offer = Offer.find(offer.id)
    assert offer.photo.file?, "Should not remove photo image file"
  end
  
  def test_clear_photo
    offer = offers(:my_space_burger_king_free_fries)
    offer.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    offer.save!

    assert offer.photo.file?, "Should have offer file"
    
    @request.session[:user_id] = users(:aaron)
    xhr :post, :clear_photo, :id => offer.to_param
    assert_response :success

    # Get latest attachment state from DB
    offer = Offer.find(offer.id)
    assert !offer.photo.file?, "Should remove photo image file"
  end
  
  def test_clear_offer_image
    offer = offers(:my_space_burger_king_free_fries)
    offer.offer_image = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    offer.save!

    assert offer.offer_image.file?, "Should have offer_image file"
    
    @request.session[:user_id] = users(:aaron)
    xhr :post, :clear_offer_image, :id => offer.to_param
    assert_response :success

    # Get latest attachment state from DB
    offer = Offer.find(offer.id)
    assert !offer.offer_image.file?, "Should remove offer_image file"
  end

  def test_clear_offer_image_invalid_offer
    offer = offers(:my_space_burger_king_free_fries)
    offer.offer_image = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    offer.save!
    
    # Bypass validation
    offer.txt_message = "Message with bad chars: •ªº"
    offer.save(false)
    offer.reload
    assert_equal "Message with bad chars: •ªº", offer.txt_message, "txt_message"
    assert !offer.valid?, "Offers should not be valid with bad TXT characters"
    
    @request.session[:user_id] = users(:aaron)
    xhr :post, :clear_offer_image, :id => offer.to_param
    assert_response :success

    assert @response.body.include?("Txt message contains one or more disallowed characters"), 
      "Expected error message in #{@response.body}"

    # Get latest attachment state from DB
    offer = Offer.find(offer.id)
    assert offer.offer_image.file?, "Should not remove offer image file"
  end

  def test_public_index
    publisher = publishers(:my_space)
    publisher.update_attribute :show_gift_certificate_button, true

    5.times { |i| create_offer_for publishers(:my_space), :index => i }
    get(:public_index, :publisher_id => publishers(:my_space).to_param)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_equal 4, assigns(:offers).size, "Number of offers"
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
    assert_no_tag :tag => "div", :attributes => { :id => "categories" },
      :descendant => { :tag => "ul", :attributes => { :class => "subcategories" } }
    assert_equal publishers(:my_space).to_param, assigns(:publisher_id), "@publisher_id as id"
    assert_equal 6, assigns(:offers_count), "@offers_count"
    assert_select ".gift_certificates", 0, "Should not display deal certificates"
  end
  
  def test_public_index_for_aamedge_shows_offers_market_menu
    pub_group = Factory :publishing_group, :label => "aamedge"
    publisher = Factory :publisher, :label => "aamedge-eastvalley", :publishing_group => pub_group, :theme => "withtheme"
    market = Factory(:market, :publisher => publisher)
    
    get :public_index, :publisher_id => publisher.to_param
    assert_response :success
  end

  def test_public_index_single_offer
    5.times { |i| create_offer_for publishers(:my_space), :index => i }
    offer = offers(:my_space_burger_king_free_fries)
    get(:public_index, :publisher_id => publishers(:my_space).to_param, :offer_id => offer)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_equal 1, assigns(:offers).size, "Number of offers"
    assert_equal offer, assigns(:offers).first, "@offer"
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
  end  
  
  def test_public_index_with_a_deleted_single_offer
    offer = offers(:my_space_burger_king_free_fries)
    offer.delete!
    get(:public_index, :publisher_id => publishers(:my_space).to_param, :offer_id => offer)
    assert_response(:not_found)
  end
  
  def test_public_index_with_advertiser_id
    publisher = publishers(:houston_press)
    advertiser = publisher.advertisers.create!( :listing => "mylisting" )
    5.times { |i| advertiser.offers.create!(:message => "Message #{i}") }
    
    get( :public_index, :publisher_id => publisher.to_param, :advertiser_id => advertiser.id )
    assert_response :success 
    assert_not_nil  assigns(:offers), "assigns @offers"
    assert_equal    advertiser, assigns(:advertiser)
    assert_equal    4, assigns(:offers).size, "the page size"
    assert_equal    5, assigns(:offers_count), "total number of offers"
    
  end
  
  def test_public_index_recognize_publisher_page_preference
    publisher = publishers(:journal_register)
    advertiser = publisher.advertisers.create!( :listing => "mylisting" )
    21.times { |i| advertiser.offers.create!(:message => "Message #{i}") }
    
    get( :public_index, :publisher_id => publisher.to_param )
    assert_response :success 
    assert_equal    20, assigns(:offers).size, "the page size"    
  end
  
  def test_public_index_with_advertiser_id_with_invalid_id
    publisher = publishers(:houston_press)
    get :public_index, :publisher_id => publisher.to_param, :advertiser_id => "blah"
    assert_response :success
    assert          assigns(:offers).empty?
  end

  def test_public_index_single_offer_without_custom_layout
    publisher = Factory(:publisher, :name => "New", :label => "new", :theme => "standard")
    5.times { |i| create_offer_for publisher, :index => i }
    offer = publisher.offers.last
    get(:public_index, :publisher_id => publisher, :offer_id => offer)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_equal 1, assigns(:offers).size, "Number of offers"
    assert_equal offer, assigns(:offers).first, "@offer"
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
  end

  def test_public_index_single_offer_with_custom_layout
    publisher = publishers(:sdreader)
    5.times { |i| create_offer_for publisher, :index => i }
    offer = publisher.offers.last
    offer.offer_image = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    offer.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    offer.save!
    advertiser = offer.advertiser
    advertiser.logo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/burger_king.png", 'image/png')
    advertiser.save!
    
    get(:public_index, :publisher_id => publisher, :offer_id => offer)
    
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_equal 1, assigns(:offers).size, "Number of offers"
    assert_equal offer, assigns(:offers).first, "@offer"
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_select "meta[name=og:image]"
    assert_select("meta[content=?]", %r{http://s3.amazonaws.com/logos.advertisers.analoganalytics.com/test/\d+/facebook.png(.*)})
  end

  def test_public_index_page_out_of_range
    get(:public_index, :publisher_id => publishers(:my_space).to_param, :text => "vuelta a espagne", :page => 4)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_equal 0, assigns(:offers).size, "Number of offers"
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
    assert_no_tag :tag => "div", :attributes => { :id => "categories" },
      :descendant => { :tag => "ul", :attributes => { :class => "subcategories" } }
  end 
  
  # Local.com's SiteID
  def test_locm_public_index_by_label
    publisher = Factory(:publisher, :name => "Brainerd Dispatch", :label => "1337")
    publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")

    @request.host = "locm.analoganalytics.com"

    get(:public_index, :publisher_id => "1337")
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_equal publisher, assigns(:publisher), "@publisher"
    assert_equal publisher.label, assigns(:publisher_id), "@publisher_id as label"
  end
  
  def test_public_index_standard_iframe_layout
    publisher = publishers(:tucsonweekly)
    get :public_index, :publisher_id => publisher.to_param, :layout => "iframe"
    assert_layout "offers/public_index"
    assert_template "offers/standard/public_index"
    assert_select "link[href=?]", /\/stylesheets\/offers.css.*/
    assert_select "link[href=?]", /\/stylesheets\/standard\/offers.css.*/
  end

  def test_public_index_with_category_nothing_found
    get(:public_index, :publisher_id => publishers(:my_space).to_param, :category_id => categories(:household).to_param)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert(assigns(:offers).empty?, "Should not include Burger King in Household category")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_equal_arrays([ categories(:household) ], assigns(:categories), "@categories")
    assert_equal(categories(:household), assigns(:category), "@category")
    assert_layout("offers/public_index")
  end

  def test_public_index_simple_format
    publisher = publishers(:my_space)
    publisher.theme = "simple"
    get(:public_index, :publisher_id => publisher.to_param)
    assert_response(:success)
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
  end 

  def test_public_index_enhanced_format
    publisher = publishers(:my_space)
    publisher.theme = "enhanced"
    get(:public_index, :publisher_id => publisher.to_param)
    assert_response(:success)
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
  end

  def test_public_index_narrow_format
    publisher = publishers(:my_space)
    publisher.theme = "narrow"
    get(:public_index, :publisher_id => publisher.to_param)
    assert_response(:success)
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
  end 
  
  def test_public_index_with_category
    get(:public_index, :publisher_id => publishers(:my_space).to_param, :category_id => categories(:restaurants).to_param)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert(assigns(:offers).include?(offers(:my_space_burger_king_free_fries)), "Should include Burger King in Restaurants category")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
    assert_no_tag :tag => "div", :attributes => { :id => "categories" },
      :descendant => { :tag => "ul", :attributes => { :class => "subcategories" } }
    assert_equal_arrays [categories(:restaurants)], assigns(:categories), "@categories"
    assert_equal(categories(:restaurants), assigns(:category), "@category")
  end

  def test_public_index_with_categories
    get(:public_index, 
        :publisher_id => publishers(:my_space).to_param, 
        :category_id => [ categories(:household), categories(:restaurants) ])
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert(assigns(:offers).include?(offers(:my_space_burger_king_free_fries)), "Should include Burger King in Restaurants category")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
    assert_no_tag :tag => "div", :attributes => { :id => "categories" },
      :descendant => { :tag => "ul", :attributes => { :class => "subcategories" } }
    assert_equal_arrays [categories(:household), categories(:restaurants)].sort_by(&:name), assigns(:categories).sort_by(&:name), "@categories"
    assert_equal(nil, assigns(:category), "@category")
  end

  def test_public_index_many_categories
    30.times { |i| create_offer_for publishers(:my_space), :index => i, :categories => [ Category.create!(:name => "Category #{i}") ] }
    offer = offers(:my_space_burger_king_free_fries)
    get(:public_index, :publisher_id => publishers(:my_space).to_param)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_equal 4, assigns(:offers).size, "Number of offers"
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
  end

  def test_public_index_with_subcategories_off
    category = categories(:restaurants)
    category.children.create!(:name => "Italian")
    
    offer = offers(:my_space_burger_king_free_fries)
    brewpubs = category.children.create!(:name => "Brewpubs")
    offer.categories << brewpubs
    offer.save!
    
    get(:public_index, :publisher_id => publishers(:my_space).to_param, :category_id => category)
    assert_response(:success)
    assert !@response.body["Brewpubs"], " Should not show Brewpubs category response body"
    assert !@response.body["Italian"], " Should not show Italian category response body"
  end

  def test_public_index_with_subcategories_on
    publisher = publishers(:my_space)
    publisher.subcategories = true
    publisher.save!
    
    category = categories(:restaurants)
    category.children.create!(:name => "Italian")
    
    offer = offers(:my_space_burger_king_free_fries)
    brewpubs = category.children.create!(:name => "Brewpubs")
    offer.categories << brewpubs
    offer.save!
    
    get(:public_index, :publisher_id => publishers(:my_space).to_param, :category_id => category)
    assert_response(:success)
    assert_select "div#categories ul" do
      assert_select "ul.subcategories"
    end
    assert_match "Brewpubs", @response.body, "response body"
    assert !@response.body["Italian"], "Should not show Italian category"
  end

  # Test has a 1/16 chance of a false-negative 
  def test_public_index_random_order
    publisher = publishers(:my_space)
    publisher.random_coupon_order = true
    publisher.save!

    performance = publisher.advertisers.create!(:name => "Performance").offers.create!( :message => "msg")
    excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!( :message => "msg")
    colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!( :message => "msg")

    get :public_index, :publisher_id => publisher.to_param
    
    assert_response(:success)
    assert_not_nil assigns(:order), "@order"
    my_space = offers(:my_space_burger_king_free_fries)
    expected_offers = [ my_space, performance, excell, colorado ]
    offers = assigns(:offers)
    expected_offers.sort! { |a, b| (a.id ^ assigns(:order)) <=> (b.id ^ assigns(:order)) }
    assert_equal expected_offers, offers, "Should randomize coupons."
  end
  
  def test_public_index_random_order_with_some_offers_being_category_featured
    publisher = publishers(:my_space)
    publisher.random_coupon_order = true
    publisher.save!

    performance = publisher.advertisers.create!(:name => "Performance").offers.create!( :message => "msg")
    excell      = publisher.advertisers.create!(:name => "Excell Sports").offers.create!( :message => "msg", :featured => 'category')
    colorado    = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!( :message => "msg")

    get :public_index, :publisher_id => publisher.to_param
    
    assert_response(:success)
    assert_not_nil assigns(:order), "@order"
    my_space = offers(:my_space_burger_king_free_fries)
    expected_offers = [ my_space, performance, excell, colorado ]
    offers = assigns(:offers)
    expected_offers.sort! { |a, b| (a.id ^ assigns(:order)) <=> (b.id ^ assigns(:order)) }
    assert_equal expected_offers, offers, "Should randomize coupons."    
  end

  # Test has a 1/16 chance of a false-negative 
  def test_public_index_alpha_order
    publisher = publishers(:my_space)

    performance = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "Offer 1")
    excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!(:message => "Offer 1")
    colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!(:message => "Offer 1")

    get :public_index, :publisher_id => publisher.to_param
    
    assert_response(:success)
    assert_nil assigns(:order), "@order"
    my_space = offers(:my_space_burger_king_free_fries)
    expected_offers = [ my_space, colorado, excell, performance ]
    offers = assigns(:offers)
    assert_equal expected_offers, offers, "Should sort coupons in alpha-order."
  end
  
  def test_public_index_with_enable_search_by_publishing_group_with_no_search_params
    valid_store_attributes = {
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Portland",
      :state => "OR",
      :zip => "97206",
      :phone_number => "858-123-4567"
    } 
    
    publishing_group = PublishingGroup.create!( :name => "Publishing Group 1" )
    
    publisher_1   = Factory(:publisher,  
      :name => "Publisher 1", 
      :publishing_group => publishing_group, 
      :enable_search_by_publishing_group => true,
      :default_offer_search_postal_code => "97206",
      :default_offer_search_distance => "20" )
    advertiser_1  = publisher_1.advertisers.create!( :name => "Pub 1 Advert 1" )
    store_1       = advertiser_1.stores.create( valid_store_attributes )
    offer_1       = advertiser_1.offers.create!( :message => "Pub 1 Advert 1 Offer 1")
    
    assert publishing_group, publisher_1.publishing_group
    assert publisher_1.enable_search_by_publishing_group, "should enable search by publishing group"
    assert 1, publisher_1.offers.size
    
    publisher_2   = Factory(:publisher,  :name => "Publisher 2", :publishing_group => publishing_group, :enable_search_by_publishing_group => false )
    advertiser_2  = publisher_2.advertisers.create!( :name => "Pub 2 Advert 2" )
    store_2       = advertiser_2.stores.create( valid_store_attributes.merge( :zip => "97217") )
    offer_2       = advertiser_2.offers.create!( :message => "Pub 2 Advert 2 Offer 2")    
    
    assert publishing_group, publisher_2.publishing_group
    assert !publisher_2.enable_search_by_publishing_group, "should NOT enable search by publishing group"
    assert 1, publisher_2.offers.size                       
    
    Offer.stubs( :zip_codes_from_search_request ).returns(["97206", "97217"])
    
    get :public_index, :publisher_id => publisher_1.to_param
    assert_response :success
    assert_equal 2, assigns(:offers).size
    assert_equal "97206", assigns(:postal_code)
    assert_equal 20, assigns(:radius)
    
  end

  def test_public_index_for_businessdirectory_theme_with_category
    get(:public_index, :publisher_id => publishers(:my_space).to_param, :category_id => categories(:restaurants).to_param)
    assert_response(:success)
    assert_nil(session[:user_id], "Should not automatically login user")
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert(assigns(:offers).include?(offers(:my_space_burger_king_free_fries)), "Should include Burger King in Restaurants category")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
    assert_no_tag :tag => "div", :attributes => { :id => "categories" },
      :descendant => { :tag => "ul", :attributes => { :class => "subcategories" } }
    assert_equal_arrays [categories(:restaurants)], assigns(:categories), "@categories"
    assert_equal(categories(:restaurants), assigns(:category), "@category")
  end         
  
  def test_call
    offer = offers(:my_space_burger_king_free_fries)
    publisher = publishers(:sdh_austin)
    xhr :post, :call, :id => offer.to_param, :publisher_id => publisher.to_param
    assert_response :success
    assert_nil session[:user_id], "Should not automatically login user"
    assert_equal offer, assigns(:offer), "assigns @offer"
    lead = assigns(:lead)
    assert_not_nil lead, "@lead assignment"
    assert_equal publisher, lead.publisher
  end

  def test_public_index_with_many_coupon_clipping_modes
    publisher = publishers(:my_space)
    advertiser = advertisers(:burger_king)
    offer = offers(:my_space_burger_king_free_fries)

    advertiser.update_attributes! :coupon_clipping_modes => ["email", "txt"]
    assert advertiser.allows_clipping_via(:email)
    assert advertiser.allows_clipping_via(:txt)

    get :public_index, :publisher_id => publisher.to_param
    assert_response :success
    assert assigns(:offers).include?(offer)

    assert_select "div#offer_#{offer.id}_footer", 1 do
      assert_select "a.clip", 1
      assert_select "a.email", 1
      assert_select "a.txt", 1
    end
  end

  def test_public_index_with_no_coupon_clipping_modes
    publisher = publishers(:my_space)
    advertiser = advertisers(:burger_king)
    offer = offers(:my_space_burger_king_free_fries)

    assert !advertiser.allows_clipping_via(:email)
    assert !advertiser.allows_clipping_via(:txt)

    get :public_index, :publisher_id => publisher.to_param
    assert_response :success
    assert assigns(:offers).include?(offer)

    assert_select "div#offer_#{offer.id}_footer", 1 do
      assert_select "a.clip", 1
      assert_select "a.email", 0
      assert_select "a.txt", 0
    end
  end

  def test_public_index_with_page_size
    publisher = publishers(:my_space)
    publisher.theme = "simple"

    20.times { |i| create_offer_for publisher, :index => i }

    get(:public_index, :publisher_id => publisher.to_param, :page_size => 12)
    assert_response(:success)
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
    assert_equal 12, assigns(:offers).size, "Number of offers"
  end

  def test_public_index_with_page_size_and_iframe_dimensions
    publisher = publishers(:my_space)
    publisher.theme = "simple"

    20.times { |i| create_offer_for publisher, :index => i }

    get(:public_index, :publisher_id => publisher.to_param, :page_size => 12)
    assert_response(:success)
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
    assert_equal 12, assigns(:offers).size, "Number of offers"
  end

  def test_public_index_with_colors_and_no_search_box
    publisher = publishers(:my_space)
    publisher.search_box = false
    publisher.save!

    get(:public_index, :publisher_id => publisher.to_param, :foreground_color => "000066", :background_color => "eeeeee")
    assert_response(:success)
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_layout("offers/public_index")
    assert_equal "eeeeee", assigns(:background_color), "@background_color"
    assert_equal "000066", assigns(:foreground_color), "@foreground_color"
  end

  def test_public_index_preserves_iframe_params
    get(:public_index, 
        :publisher_id => publishers(:my_space).to_param, 
        :foreground_color => "000066", 
        :background_color => "eeeeee",
        :city => "Little Rock",
        :state => "AR",
        :iframe_height => 800,
        :iframe_width => 400,
        :layout => "iframe"
    )
    assert_response(:success)
    assert_not_nil(assigns(:offers), "assigns @offers")
    assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
    assert_equal("iframe", assigns(:layout), "@layout")
    assert_equal("400", assigns(:iframe_width), "@iframe_width")
    assert_equal("800", assigns(:iframe_height), "@iframe_height")
    assert_layout("offers/public_index")
    assert_select "input[name='background_color'][type='hidden'][value='eeeeee']"
    assert_select "input[name='foreground_color'][type='hidden'][value='000066']"
    assert_select "input[name='city'][type='hidden'][value='Little Rock']"
    assert_select "input[name='state'][type='hidden'][value='AR']"
    assert_select "input[type='hidden'][name='layout'][value='iframe']"
  end

  def test_assign_search_params_with_valid_locm_publisher_id
    publisher = publishers(:locm)
    params = { :publisher_id => publisher.label }
    @request.host = "locm.somewhere.com"
    @controller.params=params
    @controller.send(:assign_search_params)
  end
  
  def test_assign_search_params_with_invalid_locm_publisher_id
    params = { :publisher_id => "blah" }
    @request.host = "locm.somewhere.com"
    @controller.params=params
    assert_raise(ActiveRecord::RecordNotFound) {  @controller.send(:assign_search_params)}
  end
  
  def test_public_index_with_multiple_owned_offers
    publisher = publishers(:north_shore_sun)
    assert publisher.placed_offers.count > 2, "Publisher fixture should have several placed offers"

    get :public_index, :publisher_id => publisher.to_param
    assert_response :success
    publisher.placed_offers.each do |offer|
      assert_select "div.offer#offer_#{offer.id}", 1 do
        assert_select "a#print_#{offer.id}[onclick='clipCoupon(#{offer.id}, #{publisher.id}); trackCouponEvent('Print', #{offer.id}); return false;']", 1
      end
    end
    assert_select "div#categories", 1 do
      assert_select "li a[alt='Restaurants']", :count => 1, :text => "Restaurants"
      assert_select "li a[alt='Health']", :count => 1, :text => "Health"
    end
  end

  def test_public_index_with_multiple_placed_offers
    publisher = publishers(:suffolk_times)
    assert publisher.placed_offers.count > 2, "Publisher fixture should have several placed offers"
    
    get :public_index, :publisher_id => publisher.to_param
    assert_response :success
    publisher.placed_offers.each do |offer|
      assert_select "div.offer#offer_#{offer.id}", 1 do
        assert_select "a#print_#{offer.id}[onclick='clipCoupon(#{offer.id}, #{publisher.id}); trackCouponEvent('Print', #{offer.id}); return false;']", 1
      end
    end
    assert_select "div#categories", 1 do
      assert_select "li a[alt='Restaurants']", :count => 1, :text => "Restaurants"
      assert_select "li a[alt='Health']", :count => 1, :text => "Health"
    end
  end
  
  def test_public_index_with_gift_certificates
    publisher = publishers(:sdreader)
    publisher.update_attribute :show_gift_certificate_button, true
    
    offer_1 = create_offer_for(publisher, :index => 1)
    assert_equal 0, offer_1.advertiser.gift_certificates.count, "deal certificates"
    assert_equal 0, offer_1.advertiser.gift_certificates.available.count, "available deal certificates"
    assert_equal 0, offer_1.advertiser.gift_certificates.active.count, "active deal certificates"
    
    offer_2 = create_offer_for(publisher, :index => 2)
    offer_2.advertiser.gift_certificates.create! :message => "buy me", :number_allocated => 5, :price => 1, :value => 1
    assert_equal 1, offer_2.advertiser.gift_certificates.count, "deal certificates"
    assert_equal 1, offer_2.advertiser.gift_certificates.available.count, "available deal certificates"
    assert_equal 1, offer_2.advertiser.gift_certificates.active.count, "active deal certificates"
    
    offer_3 = create_offer_for(publisher, :index => 3)
    offer_3.advertiser.gift_certificates.create! :expires_on => Date.today - 2, :message => "buy me", :number_allocated => 5, :price => 1, :value => 1
    assert_equal 1, offer_3.advertiser.gift_certificates.count, "deal certificates"
    assert_equal 1, offer_3.advertiser.gift_certificates.available.count, "available deal certificates"
    assert_equal 0, offer_3.advertiser.gift_certificates.active.count, "active deal certificates"

    get :public_index, :publisher_id => publisher.to_param
    assert_response :success
    assert_equal 3, assigns(:offers).size, "@offers"
    assert_select ".gift_certificates", 1
  end

  private

  def create_offer_for(publisher, options={})
    index = options[:index] || 0
    advertiser = publisher.advertisers.create!
    advertiser.offers.create!(
      :message => "Offer #{index}",
      :categories => options[:categories] || [categories(:restaurants)]
    )
  end

end

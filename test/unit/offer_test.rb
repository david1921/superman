require File.dirname(__FILE__) + "/../test_helper"

class OfferTest < ActiveSupport::TestCase
  stub_paperclip :except => [ :test_offer_image_dimensions, :test_big_offer_image_dimensions ]
  
  test "create" do
    BitLyGateway.instance.expects(:shorten).returns("http://bit.ly/1337")
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2")
    assert_equal Offer::DEFAULT_TERMS, offer.terms, "default terms"
    assert_equal "http://bit.ly/1337", offer.bit_ly_url, "bit_ly_url"
    assert_equal offer.reload.id.to_s, offer.label, "Offer label should match ID after create"
    assert offer.showable, "Regular offer should be showable after create" 
    assert_equal 0.0, offer.popularity
  end
  
  test "create with publisher set to notify via email on coupon changes set to true" do
    BitLyGateway.instance.expects(:shorten).returns("http://bit.ly/1337")
    advertiser = advertisers(:burger_king)
    publisher  = advertiser.publisher
    publisher.update_attributes(:notify_via_email_on_coupon_changes => true, :approval_email_address => "support@somewhere.com") 
    
    assert publisher.notify_via_email_on_coupon_changes, "publisher should want to be notified"
    
    ActionMailer::Base.deliveries.clear   
    offer = advertiser.offers.create!(:message => "Offer 2")     
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
  
  test "create with publisher set to notify via email on coupon changes set to true and no approval email address" do
    BitLyGateway.instance.expects(:shorten).returns("http://bit.ly/1337")
    advertiser = advertisers(:burger_king)
    publisher  = advertiser.publisher
    publisher.update_attributes(:notify_via_email_on_coupon_changes => true, :approval_email_address => "") 
    
    assert publisher.notify_via_email_on_coupon_changes, "publisher should want to be notified"
    
    ActionMailer::Base.deliveries.clear   
    offer = advertiser.offers.create!(:message => "Offer 2")     
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
  
  test "create with publisher set to notify via email on coupon changes set to false" do
    BitLyGateway.instance.expects(:shorten).returns("http://bit.ly/1337")
    advertiser = advertisers(:burger_king)
    publisher  = advertiser.publisher
    publisher.update_attributes(:notify_via_email_on_coupon_changes => false, :approval_email_address => "support@somewhere.com") 
    
    assert !publisher.notify_via_email_on_coupon_changes, "publisher should NOT want to be notified"
    
    ActionMailer::Base.deliveries.clear   
    offer = advertiser.offers.create!(:message => "Offer 2")     
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
  
  test "create with categories" do
    BitLyGateway.instance.expects(:shorten).returns("http://bit.ly/1337")
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :categories => [categories(:dental)])
    assert_equal Offer::DEFAULT_TERMS, offer.terms, "default terms"
    assert_equal "http://bit.ly/1337", offer.bit_ly_url, "bit_ly_url"
    assert_equal offer.reload.id.to_s, offer.label, "Offer label should match ID after create"
    assert offer.showable, "Regular offer should be showable after create"
  end
  
  test "create should also create parent categories if subcategory provided" do
    BitLyGateway.instance.expects(:shorten).returns("http://bit.ly/1337")
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :categories => [categories(:dental)])
    assert_equal Offer::DEFAULT_TERMS, offer.terms, "default terms"
    assert_equal "http://bit.ly/1337", offer.bit_ly_url, "bit_ly_url"
    assert_equal offer.reload.id.to_s, offer.label, "Offer label should match ID after create"
    assert offer.showable, "Regular offer should be showable after create"
    assert_equal 2, offer.categories.size
    assert_equal true, offer.categories.include?(categories(:dental))
    assert_equal true, offer.categories.include?(categories(:health))
  end

  test "create should only allow categories in publishing groups available categories" do
    advertiser = Factory(:advertiser)
    category1 = Factory(:category)
    category2 = Factory(:category, :name => "Shoes")
    advertiser.publisher.publishing_group.categories << category1

    offer1 = Factory.build(:offer, :advertiser => advertiser, :categories => [category1], :category_names => nil)
    assert offer1.save, "offer with valid categories should save"

    offer2 = Factory.build(:offer, :advertiser => advertiser, :categories => [category2], :category_names => nil)
    assert !offer2.save, "offer with invalid categories should not save"
    assert offer2.errors.on(:categories)
    assert offer2.errors.on(:categories).include? "Shoes"
  end

  test "create with featured being 0" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :featured => 0)
    assert_equal "none", offer.featured
    assert !offer.feature_with_category?
    assert !offer.feature_without_category?
  end
  
  test "create with featured being none" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :featured => "none")
    assert_equal "none", offer.featured
    assert !offer.feature_with_category?
    assert !offer.feature_without_category?
  end  
  
  test "create with featured being 1" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :featured => 1)
    assert_equal "category", offer.featured
    assert offer.feature_with_category?
    assert !offer.feature_without_category?
  end
  
  test "create with featured being category" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :featured => "category")
    assert_equal "category", offer.featured
    assert offer.feature_with_category?
    assert !offer.feature_without_category?
  end                 
  
  test "create with featured being 2" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :featured => 2)
    assert_equal "all", offer.featured
    assert !offer.feature_with_category?
    assert offer.feature_without_category?
  end  
  
  test "create with featured being all" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :featured => "all")
    assert_equal "all", offer.featured
    assert !offer.feature_with_category?
    assert offer.feature_without_category?
  end  

  test "create with featured being 3" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :featured => 3)
    assert_equal "both", offer.featured
    assert offer.feature_with_category?
    assert offer.feature_without_category?
  end  
  
  test "create with featured being both" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2", :featured => "both")
    assert_equal "both", offer.featured
    assert offer.feature_with_category?
    assert offer.feature_without_category?
  end  
  
  
  test "create with publisher with generate coupon code set to true" do
    BitLyGateway.instance.expects(:shorten).returns("http://bit.ly/1337")
    advertiser = advertisers( :burger_king )
    publisher = advertiser.publisher
    
    assert !publisher.nil?
    
    # make sure we update the generate coupon code and coupon code prefix, and validate it
    publisher.update_attributes( :generate_coupon_code => true, :coupon_code_prefix => "SDHS10" )
    assert advertiser.publisher.generate_coupon_code?
    assert !advertiser.publisher.coupon_code_prefix.nil?
    
    offer = advertiser.offers.create!( :message => "Offer 2" )
    
    assert_equal "SDHS10#{1000 + offer.reload.id}", offer.coupon_code    
  end
  
  test "create with publisher with generate coupon code set to false" do
    BitLyGateway.instance.expects(:shorten).returns("http://bit.ly/1337")
    advertiser = advertisers( :burger_king )
    publisher = advertiser.publisher
    
    assert !publisher.nil?
    
    # make sure we update the generate coupon code and coupon code prefix, and validate it
    publisher.update_attributes( :generate_coupon_code => false, :coupon_code_prefix => "SDHS10" )
    assert !advertiser.publisher.generate_coupon_code?
    
    offer = advertiser.offers.create!( :message => "Offer 2" )
    
    assert_equal nil, offer.coupon_code
  end
  
  test "create with publisher having bit ly login and api key" do
    bit_ly_login = "sdh"
    bit_ly_api_key = "R_00000000000000000000000000000000"

    advertiser = advertisers(:changos)
    advertiser.publisher.update_attributes! :bit_ly_login => bit_ly_login, :bit_ly_api_key => bit_ly_api_key

    BitLyGateway.instance.expects(:shorten).with do |uri, login, api_key|
      bit_ly_login == login && bit_ly_api_key == api_key
    end.returns("http://bit.ly/1337")
    
    offer = advertiser.offers.create!(:message => "Offer 2")
    assert_equal "http://bit.ly/1337", offer.bit_ly_url
  end
  
  test "create with publisher lacking bit ly login and api key" do
    advertiser = advertisers(:changos)
    advertiser.publisher.update_attributes! :bit_ly_login => " ", :bit_ly_api_key => " "

    BitLyGateway.instance.expects(:shorten).with do |uri, login, api_key|
      login.blank? && api_key.blank?
    end.returns("http://bit.ly/1337")
    
    offer = advertiser.offers.create!(:message => "Offer 2")
    assert_equal "http://bit.ly/1337", offer.bit_ly_url
  end
  
  test "destroy" do
    offer = offers(:my_space_burger_king_free_fries)
    assert offer.destroy, "Can destroy Offer with no traffic"
    
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2")
    ImpressionCount.record offer, offer.publisher.id
    lead = offer.leads.create!(
      :publisher_id => offer.publisher.id,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :call_me => true
    )
    Txt.create!(:mobile_number => "19187651010", :message => "go", :source => lead)
    assert offer.destroy, "Can destroy Offer with impressions and leads"
  end

  test "offer image dimensions" do
    offer = advertisers(:burger_king).offers.create!(
      :message => "Offer 2",
      :offer_image => ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/burger_king.png", 'image/png')
    )
    assert_equal Offer::DEFAULT_TERMS, offer.terms, "default terms"
    assert_equal 504, offer.offer_image_width, "Offer image width"
    assert_equal 216, offer.offer_image_height, "Offer image height"
    
    offer.reload
    assert_equal 504, offer.offer_image_width, "Offer image width reloaded from DB"
    assert_equal 216, offer.offer_image_height, "Offer image height reloaded from DB"
  end
  
  test "big offer image dimensions" do
    offer = advertisers(:burger_king).offers.create!(
      :message => "Offer 2",
      :offer_image => ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png', true)
    )
    assert_equal(950, offer.offer_image_width, "Offer image width")
    assert_equal(1630, offer.offer_image_height, "Offer image height")
    
    offer.reload
    assert_equal(950, offer.offer_image_width, "Offer image width reloaded from DB")
    assert_equal(1630, offer.offer_image_height, "Offer image height reloaded from DB")
  end
  
  test "advertiser name" do
    offer = advertisers(:burger_king).offers.create!( :message => "Offer 2")
    assert_equal("Burger King", offer.advertiser_name, "advertiser_name")
  end
  
  test "tagline" do
    offer = advertisers(:burger_king).offers.create!( :message => "Offer 2", :message => "Custom message")
    assert_equal("Have it your way", advertisers(:burger_king).tagline, "advertiser message")
    assert_equal("Custom message", offer.message, "offer message")
  end
  
  test "txt message validation" do
    offer = advertisers(:burger_king).offers.create(
      :message => "Custom message",
      :txt_message => "Altitude Sky Lounge: Receive 5.00 off your total bill of 50.00 or more. And Much More!. One coupon per customer. Not to be combined with any other offers."
    )
    assert(offer.errors.on(:txt_message), "Shouldn't allow long txt_message")

    offer = advertisers(:burger_king).offers.create(
      :message => "Custom message",
      :txt_message => "Buy 1 Double Entree at reg price, get 2nd Double Entree at ½ price"
    )
    assert offer.invalid?, "Offer should be invalid with bad TXT message character"
    assert_match(/disallowed character/i, offer.errors.on(:txt_message))
  end
  
  test "txt message required if clipping modes include txt" do
    advertiser = advertisers(:burger_king)
    assert !advertiser.allows_clipping_via(:txt), "Advertiser fixture should not allow TXT clipping"
    
    offer = advertiser.offers.new(:message => "A fantastic opportunity awaits", :txt_message => "")
    assert offer.valid?, "Should be valid with blank TXT message if modes exclude TXT"
    
    advertiser.offers.clear
    advertiser.update_attributes! :coupon_clipping_modes => [:txt]
    offer = advertiser.offers.create(:message => "A fantastic opportunity awaits", :txt_message => "")
    assert offer.errors.on(:txt_message), "Shouldn't allow blank TXT message if modes include TXT"
  end

  test "category names" do
    offer = advertisers(:burger_king).offers.create!( :message => "Offer 2")
    assert_equal("", offer.category_names, "category_names")
    
    computers = Category.create!(:name => "Computers")
    offer.categories << computers
    assert_equal("Computers", offer.category_names, "categories")
    
    offer.categories.create!(:name => "Food")
    assert_equal("Computers, Food", offer.category_names, "categories")

    linux = computers.subcategories.create!(:name => "Linux")
    windows = computers.subcategories.create!(:name => "Windows")
    assert_equal("Computers, Food", offer.category_names, "categories")
    offer.categories << linux
    offer.categories << windows
    assert_equal("Computers: Linux, Computers: Windows, Food", offer.category_names, "categories")

    washing = Category.create!(:name => "Washing")
    washing_windows = washing.subcategories.create!(:name => "Windows")
    assert_equal("Computers: Linux, Computers: Windows, Food", offer.category_names, "categories")
    offer.categories << washing
    offer.categories << washing_windows
    assert_equal("Computers: Linux, Computers: Windows, Food, Washing: Windows", offer.category_names, "categories")

    assert_equal 6, offer.categories(true).count, "Category count. #{offer.categories.map(&:to_s).sort.join(', ')}"
    assert_raise(ActiveRecord::ActiveRecordError) { offer.categories << linux }
    assert_raise(ActiveRecord::ActiveRecordError) { offer.categories << washing_windows }
    assert_equal("Computers: Linux, Computers: Windows, Food, Washing: Windows", offer.category_names, "categories")
    assert_equal 6, offer.categories.count, "Category count after adding duplicate categories"
  end
  
  test "set category names" do
    offer = advertisers(:burger_king).offers.create!( :message => "Offer 2")
    assert_equal("", offer.category_names, "category_names")
    
    offer.update_attributes! :category_names => ""
    assert(offer.categories.empty?, "categories")
    
    offer.update_attributes! :category_names => "Food"
    assert_equal(1, offer.categories.size, "categories")
    assert_equal("Food", offer.categories.first.name, "Category name")
    
    offer.update_attributes! :category_names => "Computers, Food"
    assert_equal(2, offer.categories.size, "categories")
    
    offer.update_attributes! :category_names => "Food: Fast, Computers:Linux, Computers: Windows"
    assert_equal(5, offer.categories.size, "categories count: #{offer.categories.map(&:to_s).sort.join(', ')}")
    
    fast_food = Category.find_by_name("Fast")
    assert_not_nil fast_food, "Should have 'Fast' category"
    
    food = Category.find_by_name("Food")
    assert_not_nil food, "Should have 'Food' category"
    
    assert_equal food, fast_food.parent, "Fast parent"
    assert food.children.include?(fast_food), "Food children should include Fast"

    linux = Category.find_by_name("Linux")
    assert_not_nil linux, "Should have 'Linux' category"

    computers = Category.find_by_name("Computers")
    assert_not_nil computers, "Should have 'Computers' category"

    assert_equal computers, linux.parent, "Linux parent"
    assert_equal nil, computers.parent, "Computers parent"

    windows = Category.find_by_name("Windows")
    assert_not_nil windows, "Should have 'Windows' category"
    assert_equal computers, windows.parent, "Windows parent"

    offer.update_attributes! :category_names => "Food: Fast, Computers:Linux, Computers: Windows, Electronics: Computers, Computers, Fast"
    assert_equal(8, offer.categories.size, "categories size: #{offer.categories.map(&:full_name).sort.join(', ')}")
  end
  
  test "set category names duplicate childs" do
    offer = advertisers(:burger_king).offers.create!(
              :message => "Offer 2", 
              :category_names => "Home: Furniture, Retail: Furniture"
            )
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2")
    offer.category_names = "Home: Furniture, Retail: Furniture"
    offer.save!
  end
  
  # Production defect
  test "set category names for existing categories" do
    retail = Category.create!(:name => "Retail")
    gifts_etc = Category.create!(:name => "Gifts...Etc")
    gifts_etc_retail = gifts_etc.subcategories.create!(:name => "Retail")
    
    offer = advertisers(:burger_king).offers.create!(:message => "buy now", :category_names => "Online, Retail")
    offer.update_attributes!(:message => "new message", :category_names => "Online, Retail")
  end
  
  test "find by publisher" do
    publisher = publishers(:my_space)
    3.times do |i|
      advertiser = publisher.advertisers.create!
      advertiser.offers.create!(:message => "Advertiser #{i} : Offer 0")
    end
    offer = Offer.find_by_publisher(publisher)
    assert_not_nil offer, "Should find Offer"
  end
  
  test "address" do
    offer = offers(:my_space_burger_king_free_fries)
    
    offer.advertiser.expects(:address?).returns(false)
    assert !offer.address?, "Advertiser address false"

    offer.advertiser.expects(:address?).returns(true)
    assert offer.address?, "Advertiser address true"
  end
  
  test "find all for publisher" do
    search_request = SearchRequest.new(:publisher => publishers(:my_space), :postal_code => "92040", :radius => 5)
    offers = Offer.find_all_for_publisher(search_request)
    assert_equal 0, offers.size, "No offers in 92040 ZIP"
    
    offer = offers(:my_space_burger_king_free_fries)
    offer.advertiser.stores.create(:address_line_1 => "1 Main St", :city => "Lakeside", :state => "CA", :zip => "92040").save!
    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space).reload, :postal_code => "92040", :radius => 5
    assert_equal 1, offers.size, "Offers in 92040 ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "13035", :radius => 5
    assert_equal 0, offers.size, "No offers in 13035 ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "13035"
    assert_equal 0, offers.size, "No offers in 13035 ZIP"
  end
  
  test "find all for publisher where publisher is in group and enabled search by group and search postal code is present" do
    valid_stores_attributes = {
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Portland",
      :state => "OR",
      :zip => "97206",
      :phone_number => "858-123-4567"
    } 
    
    publishing_group = PublishingGroup.create!( :name => "Publishing Group 1" )
    
    publisher_1   = Factory(:publisher,  :name => "Publisher 1", :publishing_group => publishing_group, :enable_search_by_publishing_group => true )
    advertiser_1  = publisher_1.advertisers.create!( :name => "Pub 1 Advert 1" )
    store_1       = advertiser_1.stores.create( valid_stores_attributes )
    offer_1       = advertiser_1.offers.create!( :message => "Pub 1 Advert 1 Offer 1")
    
    assert publishing_group, publisher_1.publishing_group
    assert publisher_1.enable_search_by_publishing_group, "should enable search by publishing group"
    assert 1, publisher_1.offers.size
    
    publisher_2   = Factory(:publisher,  :name => "Publisher 2", :publishing_group => publishing_group, :enable_search_by_publishing_group => false )
    advertiser_2  = publisher_2.advertisers.create!( :name => "Pub 2 Advert 2" )
    store_2       = advertiser_2.stores.create( valid_stores_attributes.merge( :zip => "97217") )
    offer_2       = advertiser_2.offers.create!( :message => "Pub 2 Advert 2 Offer 2")    
    
    assert publishing_group, publisher_2.publishing_group
    assert !publisher_2.enable_search_by_publishing_group, "should NOT enable search by publishing group"
    assert 1, publisher_2.offers.size
    
    Offer.stubs( :zip_codes_from_search_request ).returns(["97206", "97217"])

    offers = Offer.find_all_for_publisher :publisher => publisher_1, :postal_code => "97206", :radius => 40
    assert_equal 2, offers.size, "should find offers from both publishers"
                                                                          
    offers = Offer.find_all_for_publisher :publisher => publisher_2, :postal_code => "97206", :radius => 40
    assert_equal 1, offers.size, "should find offers from just this publishers"
    
  end
  
  
  test "find all for publisher text in zips" do
    publisher = publishers(:my_space)
    
    offer = offers(:my_space_burger_king_free_fries)
    offer.advertiser.stores.create(:address_line_1 => "1 Main St", :city => "Lakeside", :state => "CA", :zip => "92040").save!
    
    advertiser = publisher.advertisers.create!(:name => "2")
    advertiser.stores.create(:address_line_1 => "1 Main St", :city => "Lakeside", :state => "CA", :zip => "92106").save!
    offer_2 = advertiser.offers.create!(:message => "advertiser 2 PEPSI")
    
    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92101", :radius => 50
    assert_equal [ offer, offer_2 ].sort, offers.sort, "Offers within 50 miles of 92101"
    
    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92106", :radius => 50
    assert_equal [ offer, offer_2 ].sort, offers.sort, "Offers within 50 miles of 92106"
    
    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92040", :radius => 50
    assert_equal [ offer, offer_2 ].sort, offers.sort, "Offers within 50 miles of 92040"

    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92101", :radius => 50, :text => "COKE"
    assert_equal [ offer ], offers.sort, "Offers within 50 miles of 92101 with COKE"

    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92106", :radius => 50, :text => "COKE"
    assert_equal [ offer ], offers.sort, "Offers within 50 miles of 92106 with COKE"

    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92106", :radius => 50, :text => "COKE"
    assert_equal [ offer ], offers.sort, "Offers within 50 miles of 92106 with COKE"

    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92101", :radius => 50, :text => "PEPSI"
    assert_equal [ offer_2 ], offers.sort, "Offers within 50 miles of 92101 with PEPSI"

    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92106", :radius => 50, :text => "PEPSI"
    assert_equal [ offer_2 ], offers.sort, "Offers within 50 miles of 92106 with PEPSI"

    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92106", :radius => 50, :text => "PEPSI"
    assert_equal [ offer_2 ], offers.sort, "Offers within 50 miles of 92106 with PEPSI"

    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92101", :radius => 50, :text => "jolt"
    assert_equal [], offers.sort, "Offers within 50 miles of 92101 with jolt"

    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92106", :radius => 50, :text => "jolt"
    assert_equal [], offers.sort, "Offers within 50 miles of 92106 with jolt"

    offers = Offer.find_all_for_publisher :publisher => publisher, :postal_code => "92106", :radius => 50, :text => "jolt"
    assert_equal [], offers.sort, "Offers within 50 miles of 92106 with jolt"
  end
  
  test "find all for publisher publisher categories" do
    cat_1 = Category.create!(:name => "One")
    cat_2 = Category.create!(:name => "Two")
    cat_3 = Category.create!(:name => "Three")
    
    offer = offers(:my_space_burger_king_free_fries)
    offer.categories << cat_1
    offer.save!

    publisher = publishers(:my_space)
    offer_2 = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "msg")
    offer_2.categories << cat_2
    offer_2.save!
    
    # No categories
    offer_3 = publisher.advertisers.create!(:name => "Nashbar").offers.create!(:message => "msg")

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space)
    assert_equal [ offer, offer_2, offer_3 ].sort, offers.sort, "Find offers with no categories"                                                    
    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :categories => Category.find(:all)
    assert_equal [ offer, offer_2 ].sort, offers.sort, "Find offers with all categories"

    offers = Offer.find_all_for_publisher :publisher => publisher, :categories => Category.find(:all), :text =>"One", :radius => 0, :postal_code => ""
    assert_equal 1, offers.size, "We only expect one to be returned"
    assert_equal [ offer ].sort, offers.sort, "Find offers with all categories"
  end
  
  test "find with radius" do
    offer = offers(:my_space_burger_king_free_fries)
    offer.advertiser.stores.create(:address_line_1 => "1 Main St", :city => "San Diego", :state => "CA", :zip => "92106").save!
    
    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92101"
    assert_equal 0, offers.size, "No offers in 92124 ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106"
    assert_equal 1, offers.size, "Offer in 92123 ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106", :radius => 5
    assert_equal 1, offers.size, "Offer in same ZIP within 5 miles"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92101", :radius => 5
    assert_equal 1, offers.size, "Offer in different ZIP within 5 miles"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92040", :radius => 1
    assert_equal 0, offers.size, "Offers in different ZIP beyond 1 mile"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92040", :radius => 50
    assert_equal 1, offers.size, "Offers in different ZIP within 50 miles"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "13035", :radius => 50
    assert_equal 0, offers.size, "Offers in different ZIP beyond 50 miles"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "13035", :radius => 15_000
    assert_equal 1, offers.size, "Offers in different ZIP within 15_000 miles"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106"
    assert_equal 1, offers.size, "nil ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106", :radius => ""
    assert_equal 1, offers.size, "blank ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106", :radius => "0"
    assert_equal 1, offers.size, "blank ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106", :radius => 0
    assert_equal 1, offers.size, "blank ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106", :radius => "5"
    assert_equal 1, offers.size, "string ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106", :radius => "foobar"
    assert_equal 1, offers.size, "non-numeric ZIP"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "94117", :radius => 10
    assert_equal 0, offers.size, "ZIP no in DB"
    
    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :radius => 5
    assert_equal 1, offers.size, "Distance, but no zip"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "", :radius => 5
    assert_equal 1, offers.size, "Distance, but no zip"
  end
  
  test "find with text and radius" do
    offer = offers(:my_space_burger_king_free_fries)
    offer.advertiser.stores.create(:address_line_1 => "1 Main St", :city => "San Diego", :state => "CA", :zip => "92106").save!
    offer.message = "oil change"
    offer.save!
    
    advertiser_2 = publishers(:my_space).advertisers.create!
    advertiser_2.stores.create(:address_line_1 => "2 Main St", :city => "San Diego", :state => "CA", :zip => "92101").save!
    offer_2 = advertiser_2.offers.create!( :message => "oil change")

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92040", :radius => "", :text => "oil change"
    assert_equal 0, offers.size, "No postal code match with no radius"
    
    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106", :radius => "", :text => "oil change"
    assert_equal [ offer ], offers, "Postal code match with no radius"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92106", :radius => "0.1", :text => "oil change"
    assert_equal 1, offers.size, "Postal code match with radius 0.1 mile"
    assert_equal [ offer ], offers, "Postal code match with radius 0.1 mile"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92101", :radius => "100", :text => "oil change"
    assert_equal 2, offers.size, "postal code match with big radius"

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :postal_code => "92040", :radius => "100", :text => "oil change"
    assert_equal 2, offers.size, "No exact postal code match with big radius"
  end
  
  test "find with non ascii text" do
    offer = offers(:my_space_burger_king_free_fries)
    offer.message = "cafe"
    offer.save!
    
    advertiser_2 = publishers(:my_space).advertisers.create!
    offer_2 = advertiser_2.offers.create!( :message => "café")

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :text => "cafe"
    assert_equal 2, offers.size, "offers.size"
    assert_equal [ offer, offer_2 ].sort, offers.sort, "Should find cafe and café offers with 'cafe'"
  end
  
  test "find case insensitive" do
    offer = offers(:my_space_burger_king_free_fries)
    offer.message = "CAFE"
    offer.save!
    
    advertiser_2 = publishers(:my_space).advertisers.create!
    offer_2 = advertiser_2.offers.create!( :message => "café")

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :text => "Cafe"
    assert_equal 2, offers.size, "offers.size"
    assert_equal [ offer, offer_2 ].sort, offers.sort, "Should find CAFE and café offers with 'Cafe'"
  end
  
  test "find by advertiser name case insensitive" do
    offer = offers(:my_space_burger_king_free_fries)

    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :text => "BURGER king"
    assert_equal 1, offers.size, "offers.size"
    assert_equal [ offer ], offers, "Should find Burger King with 'BURGER king'"
  end 
  
  test "find with featured with no featured offers" do
    offer = offers(:my_space_burger_king_free_fries)
    offer.update_attribute(:featured, "none")
    
    offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :text => "Burger King", :featured => 'true'
    assert_equal 0, offers.size, "offers.size"
  end

  test "find with featured with a featured offers" do
    #
    # NOTE: by featured means any value besides "none"
    #
    %w( all category both ).each do |featured|
      offer = offers(:my_space_burger_king_free_fries)
      offer.update_attribute(:featured, featured)
    
      offers = Offer.find_all_for_publisher :publisher => publishers(:my_space), :text => "Burger King", :featured => 'true'
      assert_equal 1, offers.size, "offers.size"
    end
  end
  
  
  test "default map url" do
    offer = advertisers(:burger_king).offers.create!( :message => "Offer 2")
    assert_equal nil, offer.map_url
  end
  
  test "map url validation" do
    offers = advertisers(:burger_king).offers
    offer = offers.create!( :message => "Offer 2", :map_url => "")
    assert_equal "", offer.map_url, "Offer should accept blank map_url"
    
    google_map_url = "http://maps.google.com/maps/ms?ie=UTF8&hl=en&msa=0&msid=115510970475060177587.0004740c5c049dfab6b99&z=9"
    offer = offers.create!(:message => "Offer 3", :map_url => google_map_url)
    assert_equal google_map_url, offer.map_url, "Offer should accept valid HTTP map_url"
    
    offer = offers.build(:message => "Offer 4", :map_url => "maps.google.com/maps/ms")
    assert !offer.valid?, "Offer should not be valid"
    assert offer.errors.on(:map_url), "Offer should have a validation error on map_url"

    offer = offers.build(:message => "Offer 5", :map_url => "http://maps.google.com@/maps/ms")
    assert !offer.valid?, "Offer should not be valid"
    assert offer.errors.on(:map_url), "Offer should have a validation error on map_url"
  end

  test "record impression" do
    offer = offers(:my_space_burger_king_free_fries)
    assert_equal(0, offer.impressions, "Impressions before record_impression")

    offer.record_impression offer.publisher.id
    assert_equal(1, offer.impressions, "Impressions after record_impression")

    offer.record_impression offer.publisher.id
    assert_equal(2, offer.impressions, "Impressions after record_impression")
  end

  test "record click" do
    offer = offers(:my_space_burger_king_free_fries)
    assert_equal(0, offer.clicks, "Clicks before record_click")

    offer.record_click offer.publisher.id
    assert_equal(1, offer.clicks, "Clicks after first record_click")

    offer = offers(:my_space_burger_king_free_fries)
    offer.record_click offer.publisher.id
    assert_equal(2, offer.clicks, "Clicks after second record_click")
  end

  test "click through rate" do
    offer = offers(:my_space_burger_king_free_fries)
    assert_equal(0, offer.click_through_rate, "click_through_rate with no data")

    offer.record_impression offer.publisher.id
    assert_equal(0, offer.click_through_rate, "click_through_rate with 1 impression")

    offer.record_click offer.publisher.id
    assert_equal(1, offer.click_through_rate, "click_through_rate with 1 impression and 1 click")

    19.times { offer.record_impression offer.publisher.id }
    offer.record_click offer.publisher.id
    assert_equal(0.1, offer.click_through_rate, "click_through_rate with 20 impression and 2 clicks")
  end

  test "leads" do
    offer = offers(:my_space_burger_king_free_fries)
    assert_equal(1, offer.leads.size, "Should have 1 coupon request")
  end

  test "publisher" do
    assert_nil(Offer.new.publisher_name, "new publisher")

    offer = advertisers(:burger_king).offers.build
    assert_equal("MySpace", offer.publisher_name, "Publisher name")
    assert_nil(offer.publisher, "Publisher :through association will be nil after offers.build")
    assert_equal("simple", offer.advertiser.publisher.theme, "Publisher theme")
  end
  
  test "active on scope" do
    advertiser = advertisers(:burger_king)
    advertiser.offers.delete_all
    
    offer_1 = advertiser.offers.create!(:message => "Offer 1")
    offer_2 = advertiser.offers.create!(:message => "Offer 2", :show_on => "Nov 1, 2008")
    offer_3 = advertiser.offers.create!(:message => "Offer 3", :expires_on => "Nov 30, 2008")
    offer_4 = advertiser.offers.create!(:message => "Offer 4", :show_on => "Nov 2, 2008", :expires_on => "Nov 30, 2008")
    offer_5 = advertiser.offers.create!(:message => "Offer 5", :show_on => "Nov 1, 2008", :expires_on => "Nov 29, 2008")
    advertiser.offers.create!(:message => "Deleted Offer", :deleted_at => Time.now)
    
    assert_active_on = lambda { |date, offers|
      offers = [*offers]
      active = advertiser.offers.active_on(Date.parse(date)).all
      offers.each { |o| assert active.include?(o), "Active offers for #{date} should include #{o.message}" }
      active.each { |a| assert offers.include?(a), "#{a.message} should not be active on #{date}" }
    }
    
    assert_active_on.call "Oct 31, 2008", [offer_1, offer_3]
    assert_active_on.call "Nov 01, 2008", [offer_1, offer_2, offer_3, offer_5]
    assert_active_on.call "Nov 02, 2008", [offer_1, offer_2, offer_3, offer_4, offer_5]
    assert_active_on.call "Nov 29, 2008", [offer_1, offer_2, offer_3, offer_4, offer_5]
    assert_active_on.call "Nov 30, 2008", [offer_1, offer_2, offer_3, offer_4]
    assert_active_on.call "Dec 01, 2008", [offer_1, offer_2]
  end

  test "unexpired scope" do
    expired_offer = Factory(:offer, :expires_on => Time.zone.today - 1.day)
    unexpired_offer = Factory(:offer, :expires_on => Time.zone.now.to_date)

    assert_contains Offer.unexpired.collect{|o| o.id}, unexpired_offer.id, "Unexpired offer was not found."
    assert_does_not_contain Offer.unexpired.collect{|o| o.id}, expired_offer.id, "Expired offer was not expected."
  end

  test "active limit validation on create with nil dates" do
    publisher = Factory(:publisher, :active_coupon_limit => nil)
    advertiser = Factory(:advertiser)
    advertiser.offers.create! :message => "Offer 1"
    advertiser.offers.create! :message => "Offer 2"
    advertiser.offers.create! :message => "Offer 3"
    advertiser.offers.create! :message => "Offer 4"
    advertiser.offers.create! :message => "Offer 5"
    
    with_publisher_or_advertiser_limit(advertiser, 3) do |limits|
      advertiser.offers.delete_all
      advertiser.offers.create! :message => "Offer 1"
      advertiser.offers.create! :message => "Offer 2"
      advertiser.offers.create! :message => "Offer 3"
    
      offer = advertiser.offers.build(:message => "Offer 4")
      assert !offer.valid?, "Offer should not be valid with 3 existing active offers and #{limits}"
      assert_match(/more than 3 active/, offer.errors.on_base, "Error message with #{limits}")
    end
  end

  test "active limit validation on create with given dates" do
    ActiveSupport::TimeWithZone.any_instance.stubs(:to_date).returns(Date.new(2008, 10, 1))

    advertiser = advertisers(:di_milles)
    with_publisher_or_advertiser_limit(advertiser, 3) do |limits|
      advertiser.offers.delete_all
    
      advertiser.offers.create! :message => "Offer 1", :show_on => "Nov 01, 2008", :expires_on => "Nov 30, 2008"
      advertiser.offers.create! :message => "Offer 2", :show_on => "Nov 15, 2008", :expires_on => "Dec 15, 2008"
      advertiser.offers.create! :message => "Offer 3", :show_on => "Nov 17, 2008", :expires_on => "Nov 28, 2008"
    
      offer = advertiser.offers.build(:message => "Offer 4", :show_on => "Nov 10, 2008", :expires_on => "Nov 20, 2008")
      assert !offer.valid?, "Offer should not be valid with 3 existing active offers and #{limits}"
      assert_match(/more than 3 active/, offer.errors.on_base, "Error message with #{limits}")
    end
  end

  test "active limit validation on update with given dates" do
    Timecop.freeze Date.new(2008, 10, 1) do
      advertiser = advertisers(:di_milles)
      with_publisher_or_advertiser_limit(advertiser, 3) do |limits|
        advertiser.offers.delete_all

        advertiser.offers.create! :message => "Offer 1", :show_on => "Nov 01, 2008", :expires_on => "Nov 30, 2008"
        advertiser.offers.create! :message => "Offer 2", :show_on => "Nov 15, 2008", :expires_on => "Dec 15, 2008"
        advertiser.offers.create! :message => "Offer 3", :show_on => "Nov 17, 2008", :expires_on => "Nov 28, 2008"
        advertiser.offers.create! :message => "Offer 4", :show_on => "Nov 01, 2008", :expires_on => "Nov 16, 2008"

        offer = advertiser.offers.find_by_message("Offer 4")
        offer.expires_on = "Nov 20, 2008"
        assert !offer.valid?, "Offer should not be valid with 3 existing active offers and #{limits}"
        assert_match(/more than 3 active/, offer.errors.on_base, "Error message with #{limits}")
      end
    end
  end
  
  test "active limit validation with zero limit" do
    ActiveSupport::TimeWithZone.any_instance.stubs(:to_date).returns(Date.new(2008, 10, 1))

    advertiser = advertisers(:di_milles)
    with_publisher_or_advertiser_limit(advertiser, 0) do |limits|
      advertiser.offers.delete_all
      
      offer = advertiser.offers.new :message => "Offer 1"
      assert !offer.valid?, "Offer should not be valid with #{limits}"
      assert_match(/any active/, offer.errors.on_base, "Error message with #{limits}")
    
      offer.show_on = "Nov 01, 2008"
      assert !offer.valid?, "Offer should not be valid with #{limits}"
      assert_match(/any active/, offer.errors.on_base, "Error message with #{limits}")
      
      offer.expires_on = "Nov 30, 2008"
      assert !offer.valid?, "Offer should not be valid with #{limits}"
      assert_match(/any active/, offer.errors.on_base, "Error message with #{limits}")

      offer.show_on = nil
      assert !offer.valid?, "Offer should not be valid with #{limits}"
      assert_match(/any active/, offer.errors.on_base, "Error message with #{limits}")
    end
  end
  
  test "active limit validation ignores deleted offer" do
    advertiser = advertisers(:di_milles)
    with_publisher_or_advertiser_limit(advertiser, 3) do |limits|
      advertiser.offers.delete_all
      
      advertiser.offers.create! :message => "Offer 1"
      advertiser.offers.create! :message => "Offer 2", :deleted_at => Time.now
      advertiser.offers.create! :message => "Offer 3"

      offer = advertiser.offers.build(:message => "Offer 4")
      assert offer.save, "Offer should be valid with 2 existing active and 1 deleted offer and #{limits}"
    
      offer = advertiser.offers.build(:message => "Offer 5")
      assert !offer.valid?, "Offer should not be valid with 3 existing active offers and #{limits}"
      assert_match(/more than 3 active/, offer.errors.on_base, "Error message with #{limits}")
    end
  end

  test "schedule order validation" do
    advertiser = advertisers(:di_milles)
    
    offer = advertiser.offers.create(:message => "Offer 1", :show_on => "Oct 01, 2008", :expires_on => "Oct 15, 2008")
    assert offer.valid?, "Should be valid with schedule dates in order"
    
    offer = advertiser.offers.create(:message => "Offer 2", :show_on => "Oct 31, 2008", :expires_on => "Oct 31, 2008")
    assert offer.valid?, "Should be valid with show and expire on the same day"
    
    offer = advertiser.offers.create(:message => "Offer 3", :expires_on => "Nov 01, 2008")
    assert offer.valid?, "Should be valid with no show date"
    
    offer = advertiser.offers.create(:message => "Offer 4", :show_on => "Nov 30, 2008")
    assert offer.valid?, "Should be valid with no expire date"
    
    offer = advertiser.offers.build(:message => "Offer 5", :show_on => "Dec 30, 2008", :expires_on => "Dec 01, 2008")
    assert !offer.valid?, "Should not be valid with schedule dates out of order"
    assert_match(/cannot be after/i,  offer.errors.on(:show_on), "Validation error message")
  end

  test "txt head" do
    advertiser = advertisers(:changos)
    assert_equal "MySDH.com", advertiser.offers.new(:message => "Offer 1").txt_head, "Offer TXT head with publisher brand header"
    advertiser.publisher.update_attributes! :brand_txt_header => nil
    assert advertiser.offers.new(:message => "Offer 2").txt_head.blank?, "Offer TXT head without publisher brand header"
  end
  
  test "txt body" do
    advertiser = advertisers(:changos)
    
    offer = advertiser.offers.new(:message => "Message 1", :txt_message => "TXT Message 1")
    assert_equal "TXT Message 1", offer.txt_body, "Offer TXT body"

    offer = advertiser.offers.new(:message => "Message 2")
    assert_equal "Message 2", offer.txt_body, "Offer TXT body"
  end
  
  test "txt foot with no expiration date" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    
    offer = advertiser.offers.create( :message => "This is my message" )
    assert_nil offer.txt_foot
  end
  
  test "txt foot with expiration date" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    date  = 10.days.from_now
    offer = advertiser.offers.create( :message => "This is my message", :expires_on => date )
    assert_equal "Exp#{offer.expires_on.strftime('%m/%d/%y')}", offer.txt_foot
  end
  
  test "txt foot with expiration date and publisher does not auto insert expiration date" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    
    advertiser.publisher.update_attribute( :auto_insert_expiration_date, false )
    
    date = 10.days.from_now
    offer = advertiser.offers.create( :message => "This is my message", :expires_on => date )
    assert_nil offer.txt_foot
  end
  
  test "txt foot with expiration date and publisher does not auto insert expiration date with coupon code" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    
    advertiser.publisher.update_attribute( :auto_insert_expiration_date, false )
    
    
    date = 10.days.from_now
    offer = advertiser.offers.create( :message => "This is my message", :expires_on => date, :coupon_code => "SDH10" )
    assert_equal "SDH10", offer.txt_foot
  end
  
  test "txt foot with expiration date and publisher does auto insert expiration date" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    
    advertiser.publisher.update_attribute( :auto_insert_expiration_date, true )
    
    date  = 10.days.from_now
    offer = advertiser.offers.create( :message => "This is my message", :expires_on => date )
    assert_equal "Exp#{offer.expires_on.strftime('%m/%d/%y')}", offer.txt_foot
  end
  
  test "text footer with expiration date and coupon code" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    date  = 10.days.from_now
    offer = advertiser.offers.create( :message => "This is my message", :expires_on => date, :coupon_code => "SDH1010" )
    assert_equal "Exp#{offer.expires_on.strftime('%m/%d/%y')} SDH1010", offer.txt_foot    
  end
  
  test "terms with expirations with no expiration date" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    
    offer = advertiser.offers.create( :message => "This is my message." )
    assert_equal "#{Offer::DEFAULT_TERMS}.", offer.terms_with_expiration
    assert_equal "<p>#{Offer::DEFAULT_TERMS}.</p>", offer.terms_with_expiration_as_textiled
  end
  
  test "terms with expirations with no expiration date and terms that do not end with period" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    terms = "  these are my terms  "
    offer = advertiser.offers.create( :message => "This is my message.",  :terms => terms )
    assert_equal "these are my terms.", offer.terms_with_expiration
    assert_equal "<p>these are my terms.</p>", offer.terms_with_expiration_as_textiled
  end
  
  test "terms with expirations with no expiration date and terms that do end with period" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    terms = "  these are my terms.  "
    offer = advertiser.offers.create( :message => "This is my message.",  :terms => terms )
    assert_equal "these are my terms.", offer.terms_with_expiration
    assert_equal "<p>these are my terms.</p>", offer.terms_with_expiration_as_textiled
  end
  
  test "terms with expiration and publisher does not auto insert expiration date" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    
    advertiser.publisher.update_attribute( :auto_insert_expiration_date, false )
    
    date  = 10.days.from_now
    offer = advertiser.offers.create( :message => "This is my message.", :expires_on => date, :terms => " these are my terms. ") 
    assert_equal "these are my terms.", offer.terms_with_expiration    
  end
  
  test "terms with expiration and publisher does auto insert expiration date" do
    advertiser = advertisers(:changos)
    assert_not_nil advertiser.publisher
    
    advertiser.publisher.update_attribute(:auto_insert_expiration_date, true)
    date  = 10.days.from_now
    
    offer = advertiser.offers.create(:message => "This is my message.", :expires_on => date, :terms => " these are my terms. ")
    assert_equal "these are my terms. Expires #{offer.expires_on.strftime('%m/%d/%y')}.", offer.terms_with_expiration
    assert_equal "<p>these are my terms. Expires #{offer.expires_on.strftime('%m/%d/%y')}.</p>", offer.terms_with_expiration_as_textiled    

    offer = advertiser.offers.create(:message => "This is my message.", :expires_on => date, :terms => " these are my terms  ")
    assert_equal "these are my terms. Expires #{offer.expires_on.strftime('%m/%d/%y')}.", offer.terms_with_expiration
    assert_equal "<p>these are my terms. Expires #{offer.expires_on.strftime('%m/%d/%y')}.</p>", offer.terms_with_expiration_as_textiled
  end
  
  test "validation of immutable attributes" do
    advertiser = advertisers(:changos)
    
    offer = advertiser.offers.create!(:message => "Free taco when you buy a burrito")
    offer.advertiser = advertisers(:di_milles)
    assert offer.invalid?, "Should not be valid with modified advertiser ID"
    assert_match(/cannot be changed/, offer.errors.on(:advertiser_id))
  end 

  test "label validation" do
    offer_1 = advertisers(:di_milles).offers.create!(:message => "Offer One", :label => "42")
    
    advertiser = advertisers(:changos)
    offer_2 = advertiser.offers.build(:message => "Offer Two", :label => "42")
    assert offer_2.valid?, "Should be valid with duplicate label but another advertiser"
    offer_2.save!
    
    offer_3 = advertiser.offers.build(:message => "Offer Tre", :label => "43")
    assert offer_3.valid?, "Should be valid with unique label"
    
    offer_3.label = "42"
    assert offer_3.invalid?, "Should not be valid with duplicate label for the same advertiser"
  end
  
  test "create generates default placement" do
    advertiser = advertisers(:burger_king)
    offer = advertiser.offers.create!(:message => "Offer")
    assert_equal 1, offer.placements.count
    assert_equal advertiser.publisher, offer.placements.first.publisher
  end
  
  test "destroy cascades to placements" do
    offer = offers(:changos_buy_two_tacos)
    publishers = [offer.publisher] + [:sdreader, :knoxville].map { |tag| publishers(tag) }
    publishers.each { |publisher| offer.placements.create! :publisher_id => publisher.id }
    assert_equal 3, Placement.count(:conditions => { :offer_id => offer.id })
    
    offer.destroy
    assert_equal 0, Placement.count(:conditions => { :offer_id => offer.id })
  end
  
  test "placements on create with publisher in group and sharing" do
    publishing_group = PublishingGroup.create! :name => "United Publishing"
    publisher_1 = publishing_group.publishers.create(:name => "Publisher One")
    advertiser = advertisers(:burger_king)
    publisher_2 = advertiser.publisher
    publisher_2.update_attributes! :place_offers_with_group => true, :publishing_group => publishing_group
    assert_equal 2, publishing_group.publishers.count, "Should have two publishers in group"
    
    offer = advertiser.offers.create!(:message => "Offer")
    assert_equal 2, offer.placements.count
    publishing_group.publishers.each { |publisher| assert offer.placements.for_publisher(publisher) }
  end
  
  test "placements on create with publisher in group but not sharing" do
    publishing_group = PublishingGroup.create! :name => "United Publishing"
    publisher_1 = publishing_group.publishers.create(:name => "Publisher One")
    advertiser = advertisers(:burger_king)
    publisher_2 = advertiser.publisher
    publisher_2.update_attributes! :publishing_group => publishing_group
    assert_equal 2, publishing_group.publishers.count, "Should have two publishers in group"
    
    offer = advertiser.offers.create!(:message => "Offer")
    assert_equal 1, offer.placements.count
    assert_equal publisher_2, offer.placements.first.publisher
  end 
  
  test "placements on create with publisher in group with place all group offers to true" do
    publishing_group = PublishingGroup.create!( :name => "United Publishing" )
    publisher_1 = publishing_group.publishers.create(:name => "Publisher One", :place_all_group_offers => true)
    advertiser = advertisers(:burger_king)
    publisher_2 = advertiser.publisher
    publisher_2.update_attributes! :publishing_group => publishing_group
    assert_equal 2, publishing_group.publishers.count, "Should have two publishers in group"
    assert publisher_1.place_all_group_offers?
    
    offer = advertiser.offers.create!(:message => "Offer")
    assert_equal 2, offer.placements.count
    publishing_group.publishers.each { |publisher| assert offer.placements.for_publisher(publisher) }
  end 
  
  test "placements on create with publisher in group with place all group offers and place offers with group set to true" do
    publishing_group = PublishingGroup.create!( :name => "United Publishing" )
    publisher_1 = publishing_group.publishers.create(:name => "Publisher One", :place_all_group_offers => true, :place_offers_with_group => true)
    publisher_1.advertisers.create!
    advertiser = advertisers(:burger_king)
    publisher_2 = advertiser.publisher
    publisher_2.update_attributes! :publishing_group => publishing_group
    assert_equal 2, publishing_group.publishers.count, "Should have two publishers in group"
    assert publisher_1.place_all_group_offers?
    assert publisher_1.place_offers_with_group?    
    
    # when offer is created on publisher 1, publisher_2 should have a placement as well
    offer_1 = publisher_1.advertisers.first.offers.create!( :message => "Offer 1" )
    assert_equal 2, offer_1.placements.size
    assert offer_1.placements.find_by_publisher_id( publisher_1.id )
    assert offer_1.placements.find_by_publisher_id( publisher_2.id )
    
    # when offer is created on publisher 2, publisher_1 should have a placement as well
    offer_2 = publisher_2.advertisers.first.offers.create!( :message => "Offer 2" )
    assert_equal 2, offer_2.placements.size
    assert offer_2.placements.find_by_publisher_id( publisher_1.id )
    assert offer_2.placements.find_by_publisher_id( publisher_2.id )
    
  end
  
  test "placements on create with publisher sharing but not in group" do
    advertiser = advertisers(:burger_king)
    publisher = advertiser.publisher
    publisher.update_attributes! :place_offers_with_group => true
    
    offer = advertiser.offers.create!(:message => "Offer")
    assert_equal 1, offer.placements.count
    assert_equal publisher, offer.placements.first.publisher
  end
  
  test "find all for publisher with multiple placements" do
    p_1 = Factory(:publisher, :name => "Publisher One")
    a_1_1 = p_1.advertisers.create!
    a_1_1.stores.create!(:address_line_1 => "1 Main Street", :city => "San Diego", :state => "CA", :zip => "92101")
    o_1_1_1 = a_1_1.offers.create!(:message => "Free taco")

    a_1_2 = p_1.advertisers.create!
    a_1_2.stores.create!(:address_line_1 => "2 Main Street", :city => "San Diego", :state => "CA", :zip => "92106")
    o_1_2_1 = a_1_2.offers.create!(:message => "Free beans")
    
    p_2 = Factory(:publisher, :name => "Publisher Two")
    a_2_1 = p_2.advertisers.create!
    a_2_1.stores.create!(:address_line_1 => "3 Main Street", :city => "San Diego", :state => "CA", :zip => "92101")
    o_2_1_1 = a_2_1.offers.create!(:message => "Free salsa")

    o_1_1_1.place_with([p_1])
    o_1_2_1.place_with([p_1, p_2])
    o_2_1_1.place_with([p_1, p_2])

    assert_equal [o_1_1_1, o_1_2_1, o_2_1_1].sort, Offer.find_all_for_publisher(:publisher => p_1).sort
    assert_equal [o_1_2_1, o_2_1_1].sort, Offer.find_all_for_publisher(:publisher => p_2).sort
    assert_equal [o_1_1_1], Offer.find_all_for_publisher(:publisher => p_1, :text => "TACO")
    assert_equal [o_1_2_1], Offer.find_all_for_publisher(:publisher => p_2, :text => "BEAN")
    assert_equal [o_1_1_1, o_2_1_1].sort, Offer.find_all_for_publisher(:publisher => p_1, :postal_code => "92101", :radius => "0").sort
    assert_equal [o_1_1_1, o_1_2_1, o_2_1_1].sort, Offer.find_all_for_publisher(:publisher => p_1, :postal_code => "92101", :radius => "5").sort
    assert_equal [o_1_2_1, o_2_1_1].sort, Offer.find_all_for_publisher(:publisher => p_2, :postal_code => "92101", :radius => "5").sort
    assert_equal [o_1_1_1], Offer.find_all_for_publisher(:publisher => p_1, :postal_code => "92101", :radius => "5", :text => "TACO")
  end

  test "validation with category too deep" do
    offer = advertisers(:changos).offers.build(:message => "Free Taco", :category_names => "Tacos: Yummy: Truly")
    assert offer.invalid?, "Offer should not be valid with invalid category name"
    assert offer.errors.on(:categories)
    
    assert_equal "Tacos: Yummy: Truly", offer.category_names
    assert !Category.find_by_name("Tacos"), "Should not create a Tacos category"
    assert !Category.find_by_name("Yummy"), "Should not create a Yummy category"
    assert !Category.find_by_name("Truly"), "Should not create a Truly category"
  end
  
  test "create with name as category and subcategory" do
    offer = advertisers(:changos).offers.build(:message => "Free Taco", :category_names => " Tacos:  Yummy  , Yummy : Tacos ")
    assert offer.valid?, "Offer should be valid with duplicate category names"
    
    assert !Category.find_by_name("Tacos"), "Should not create a Tacos category before save"
    assert !Category.find_by_name("Yummy"), "Should not create a Yummy category before save"
    
    offer.save!
    assert_equal "Tacos: Yummy, Yummy: Tacos", offer.category_names
    assert((tacos_top = Category.find_by_name_and_parent_id("Tacos", nil)), "Should create a Tacos category")
    assert((yummy_top = Category.find_by_name_and_parent_id("Yummy", nil)), "Should create a Yummy category")
    assert((tacos_sub = Category.find_by_name_and_parent_id("Tacos", yummy_top)), "Should create a Tacos subcategory")
    assert((yummy_sub = Category.find_by_name_and_parent_id("Yummy", tacos_top)), "Should create a Yummy subcategory")
    
    assert_equal [tacos_top, yummy_top, tacos_sub, yummy_sub].sort_by(&:id), offer.categories.sort_by(&:id)
  end
  
  test "create with name as different subcategories" do
    offer = advertisers(:changos).offers.build(:message => "Free Taco", :category_names => " Tacos:  Yummy  , Foods : Yummy ")
    assert offer.valid?, "Offer should be valid with duplicate category names"
    
    assert !Category.find_by_name("Tacos"), "Should not create a Tacos category before save"
    assert !Category.find_by_name("Yummy"), "Should not create a Yummy category before save"
    assert !Category.find_by_name("Foods"), "Should not create a Foods category before save"
    
    offer.save!
    assert_equal "Foods: Yummy, Tacos: Yummy", offer.category_names
    assert((tacos= Category.find_by_name_and_parent_id("Tacos", nil)), "Should create a Tacos category")
    assert((foods = Category.find_by_name_and_parent_id("Foods", nil)), "Should create a Yummy category")
    assert((yummy_1 = Category.find_by_name_and_parent_id("Yummy", tacos)), "Should create a Yummy subcategory of Tacos")
    assert((yummy_2 = Category.find_by_name_and_parent_id("Yummy", foods)), "Should create a Yummy subcategory of Foods")
    
    assert_equal [tacos, foods, yummy_1, yummy_2].sort_by(&:id), offer.categories.sort_by(&:id)
  end
  
  test "create with blank category name" do
    offer = advertisers(:changos).offers.build(:message => "Free Taco", :category_names => " Tacos:  Yummy  , ")
    assert offer.valid?, "Offer should be valid with blank category name"
    
    assert !Category.find_by_name("Tacos"), "Should not create a Tacos category before save"
    assert !Category.find_by_name("Yummy"), "Should not create a Yummy category before save"
    
    offer.save!
    assert_equal "Tacos: Yummy", offer.category_names
    assert((tacos = Category.find_by_name("Tacos")), "Should create a Tacos category")
    assert((yummy = Category.find_by_name("Yummy")), "Should create a Yummy category")
    assert_equal [tacos, yummy].sort_by(&:id), offer.categories.sort_by(&:id)
  end
  
  test "create with blank subcategory name" do
    offer = advertisers(:changos).offers.build(:message => "Free Taco", :category_names => " Tacos:  ")
    assert offer.valid?, "Offer should be valid with blank subcategory name"
    
    assert !Category.find_by_name("Tacos"), "Should not create a Tacos category before save"
    
    offer.save!
    assert_equal "Tacos", offer.category_names
    assert((tacos = Category.find_by_name("Tacos")), "Should create a Tacos category")
    assert_equal [tacos], offer.categories
  end
  
  test "update categories as names" do
    tacos = Category.create!(:name => "Tacos")
    foods = Category.create!(:name => "Foods")
    offer = advertisers(:changos).offers.create!(:message => "Free Taco")
    offer.categories << tacos
    offer.categories << foods
    assert_equal [tacos, foods].sort_by(&:id), offer.categories.sort_by(&:id), "Should have assigned categories"
    assert_equal "Foods, Tacos", offer.category_names
    
    offer.category_names = offer.category_names
    offer.save!
    assert_equal [tacos, foods].sort_by(&:id), offer.categories.sort_by(&:id), "Should still have assigned categories after save"
    assert_equal "Foods, Tacos", offer.category_names
    
    offer.update_attributes! :category_names => "Tacos, Yummy"
    assert((yummy = Category.find_by_name_and_parent_id("Yummy", nil)), "Should create category Yummy")
    assert_equal [tacos, yummy].sort_by(&:id), offer.categories.sort_by(&:id), "Should have updated categories"
    assert_equal "Tacos, Yummy", offer.category_names
  end
  
  test "facebook description" do
    offer = offers(:changos_buy_two_tacos)
    advertiser = offer.advertiser
    
    assert_facebook_description = lambda do |*args|
      description = args.shift
      advertiser.name, advertiser.tagline, offer.message, offer.terms = *args
      assert_equal description, offer.facebook_description, args.join(", ")
    end
    assert_facebook_description.call "Adver tiser: Tag line; My message; My terms.", "Adver tiser", "Tag line", "My message", "My terms"
    assert_facebook_description.call "Adver tiser: Tag line; My message; My terms.", " Adver tiser ", " Tag line ", " My message ", " My terms "
    assert_facebook_description.call "Adver tiser: Tag line; My message; My terms.", " Adver tiser ", " Tag line. ", " My message. ", " My terms. "
    assert_facebook_description.call "Adver tiser; My message; My terms.", " Adver tiser ", "", " My message. ", " My terms. "
    assert_facebook_description.call "Adver tiser; My message; My terms.", " Adver tiser ", nil, " My message. ", " My terms. "
    assert_facebook_description.call "Adver tiser; My message.", " Adver tiser ", nil, " My message. ", ""
    assert_facebook_description.call "Adver tiser; My message.", " Adver tiser ", nil, " My message. ", nil
  end
  
  test "facebook description should add period" do
    offer = offers(:my_space_burger_king_free_fries)
    offer.advertiser.name = "1550 Hyde"
    offer.advertiser.tagline = nil
    offer.message = "3 Course Pri-Fixe Dinner $29.95"
    offer.terms = "Selection changes Daily "
    assert_equal(
      "1550 Hyde; 3 Course Pri-Fixe Dinner $29.95; Selection changes Daily.", 
      offer.facebook_description, 
      "facebook_description"
    )
  end
  
  test "facebook description should not add period after exclamation" do
    offer = offers(:my_space_burger_king_free_fries)
    offer.advertiser.name = "1550 Hyde"
    offer.advertiser.tagline = nil
    offer.message = "3 Course Pri-Fixe Dinner $29.95"
    offer.terms = "Selection changes Daily!"
    assert_equal(
      "1550 Hyde; 3 Course Pri-Fixe Dinner $29.95; Selection changes Daily!", 
      offer.facebook_description, 
      "facebook_description"
    )
  end
  
  test "showable for regular advertiser" do
    advertiser = advertisers(:changos)
    assert !advertiser.paid, "Advertiser fixture should have paid flag set"
    assert advertiser.active?, "Advertiser fixture should be active"
    
    offer = advertiser.offers.create!(:message => "Free saganaki")
    assert offer.showable, "Offer should be marked showable after create"
    
    offer.delete!
    assert !offer.reload.showable, "Offer should not be marked showable after delete"
  end
  
  test "showable for paid advertiser" do
    advertiser = publishers(:sdh_austin).advertisers.create!(
      :name => "Paid Advertiser",
      :paid => true,
      :subscription_rate_schedule => subscription_rate_schedules(:sdh_austin_rates)
    )
    assert advertiser.paid, "Advertiser fixture should have paid flag set"
    assert !advertiser.active?, "Advertiser fixture should not be active"
    
    offer = advertiser.offers.create!(:message => "Free taco")
    assert !offer.deleted?, "Offer should not be marked deleted after create"
    assert !offer.showable, "Offer should not be marked showable after create"
    
    offer.delete!
    assert !offer.reload.showable, "Offer should not be marked showable after delete"
  end
  
  test "equality" do
    same_1 = offers(:my_space_burger_king_free_fries)
    same_2 = Offer.find(same_1.id)
    different = offers(:changos_buy_two_tacos)
    assert same_1 == same_1, "same_1 == same_1"
    assert same_2 == same_2, "same_2 == same_2"
    assert same_1 == same_2, "same_1 == same_2"
    assert same_2 == same_1, "same_2 == same_1"
    assert same_1 != different, "same_1 != different"
    assert same_2 != different, "same_2 != different"
    assert different != same_1, "different != same_1"
    assert different != same_2, "different != same_2"
  end
  
  test "difference" do
    offer_1 = offers(:my_space_burger_king_free_fries)
    offer_2 = offers(:changos_buy_two_tacos)
    offer_3 = offers(:bella_smiles_free_toothbrush)
    
    assert(([ offer_1 ] - [ offer_1]) == [], "[ offer_1 ] - [ offer_1]")
    assert(([ offer_2 ] - [ offer_2]) == [], "[ offer_2 ] - [ offer_2]")
    assert(([ offer_1 ] - [ offer_2]) == [ offer_1 ], "[ offer_1 ] - [ offer_2]")
    assert(([ offer_2 ] - [ offer_1]) == [ offer_2 ], "[ offer_2 ] - [ offer_1]")
    assert(([ offer_2, offer_3 ] - [ offer_1]) == [ offer_2, offer_3 ], "[ offer_2, offer_3 ] - [ offer_1]")
    assert(([ offer_2, offer_1 ] - [ offer_1]) == [ offer_2 ], "[ offer_2, offer_1 ] - [ offer_1]")
    assert(([ offer_1 ] - [ offer_2, offer_3 ]) == [ offer_1 ], "[ offer_1] - [ offer_2, offer_3]")
    assert(([ offer_1 ] - [ offer_2, offer_1 ]) == [ ], "[ offer_1] - [ offer_2, offer_1]")
    assert(([] - [ offer_1]) == [], "[ ] - [ offer_1]")
    assert(([ offer_1 ] - []) == [ offer_1 ], "[ offer_1 ] - []")
  end
  
  test "compare" do
    advertiser_a = publishers(:sdh_austin).advertisers.build(:name => "A")
    advertiser_b = publishers(:sdh_austin).advertisers.build(:name => "B")

    offer_b_1_n = Offer.new(:advertiser => advertiser_b, :featured => "none")
    offer_b_1_n.id = 1
    offer_a_2_n = Offer.new(:advertiser => advertiser_a, :featured => "none")
    offer_a_2_n.id = 2

    offer_a_4_c = Offer.new(:advertiser => advertiser_a, :featured => "category")
    offer_a_4_c.id = 4
    offer_b_5_b = Offer.new(:advertiser => advertiser_b, :featured => "both")
    offer_b_5_b.id = 5
    offer_a_6_a = Offer.new(:advertiser => advertiser_a, :featured => "all")
    offer_a_6_a.id = 6
    
    [true, false].each do |randomize|
      [offer_b_1_n, offer_a_2_n].each do |non_featured_offer|
        assert_equal(-1, Offer.compare(offer_a_4_c, non_featured_offer, true, randomize, 0))
      end
    end
    assert_equal(+1, Offer.compare(offer_a_4_c, offer_b_1_n, false, true, 0))
    assert_equal(-1, Offer.compare(offer_a_4_c, offer_b_1_n, false, false, 0))
    assert_equal(+1, Offer.compare(offer_a_4_c, offer_a_2_n, false, true, 0))
    assert_equal(0, Offer.compare(offer_a_4_c, offer_a_2_n, false, false, 0))
    
    [true, false].each do |with_category|
      [true, false].each do |randomize|
        [offer_b_1_n, offer_a_2_n].each do |non_featured_offer|
          assert_equal(-1, Offer.compare(offer_b_5_b, non_featured_offer, with_category, randomize, 0))
        end
      end
    end

    [true, false].each do |randomize|
      [offer_b_1_n, offer_a_2_n].each do |non_featured_offer|
        assert_equal(-1, Offer.compare(offer_a_6_a, non_featured_offer, false, randomize, 0))
      end
    end
    assert_equal(+1, Offer.compare(offer_a_6_a,  offer_b_1_n, true, true, 0))
    assert_equal(-1, Offer.compare(offer_a_6_a, offer_b_1_n, true, false, 0))
    assert_equal(+1, Offer.compare(offer_a_6_a, offer_a_2_n, true, true, 0))
    assert_equal( 0, Offer.compare(offer_a_6_a, offer_a_2_n, true, false, 0))

    [true, false].each do |with_category|
      assert_equal(-1, Offer.compare(offer_b_1_n, offer_a_2_n, with_category, true, 0))
      assert_equal(+1, Offer.compare(offer_b_1_n, offer_a_2_n, with_category, false, 0))
    end

    assert_equal(-1, Offer.compare(offer_b_5_b, offer_a_6_a, true, true, 0))
    assert_equal(-1, Offer.compare(offer_b_5_b, offer_a_6_a, true, false, 0))
    assert_equal(-1, Offer.compare(offer_b_5_b, offer_a_6_a, false, true, 0))
    assert_equal(+1, Offer.compare(offer_b_5_b, offer_a_6_a, false, false, 0))
                 
    assert_equal(-1, Offer.compare(offer_b_5_b, offer_a_4_c, false, true, 0))
    assert_equal(-1, Offer.compare(offer_b_5_b, offer_a_4_c, false, false, 0))
    assert_equal(+1, Offer.compare(offer_b_5_b, offer_a_4_c, true, true,  0))
    assert_equal(+1, Offer.compare(offer_b_5_b, offer_a_4_c, true, false, 0))
                 
    assert_equal(-1, Offer.compare(offer_a_4_c, offer_a_6_a, true, true, 0))
    assert_equal(-1, Offer.compare(offer_a_4_c, offer_a_6_a, true, false, 0))
    assert_equal(+1, Offer.compare(offer_a_4_c, offer_a_6_a, false, true, 0))
    assert_equal(+1, Offer.compare(offer_a_4_c, offer_a_6_a, false, false, 0))
  end
  
  test "update popularity with no click counts" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2")
    assert_equal 0.0, offer.popularity
    offer.update_popularity!
    assert_equal 0.0, offer.popularity
  end
  
  test "update popularity with 1 click that was for today" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2")
    assert_not_nil offer.publisher
    offer.click_counts.create!( :count => 1, :created_at => Time.zone.now, :publisher_id => offer.publisher.id )
    offer.update_popularity!
    assert_equal 1.0, offer.popularity.to_f
  end 
  
  test "update popularity with 2 clicks today and 1 click yesterday" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2")
    offer.click_counts.create!( :count => 2, :created_at => Time.zone.now, :publisher_id => offer.publisher.id )
    offer.click_counts.create!( :count => 1, :created_at => Time.zone.now - 24.hours, :publisher_id => offer.publisher.id )
    offer.update_popularity!
    assert_equal 2.8, offer.popularity.to_f
  end
  
  test "update popularity with 3 clicks today and 2 clicks to days ago and 10 clicks 8 days ago" do
    offer = advertisers(:burger_king).offers.create!(:message => "Offer 2")
    Timecop.freeze Time.utc(2011, 3, 9, 10, 11) do
      offer.click_counts.create!( :count => 3, :created_at => Time.zone.now, :publisher_id => offer.publisher.id )
      offer.click_counts.create!( :count => 2, :created_at => Time.zone.now.yesterday - 1.day, :publisher_id => offer.publisher.id )
      offer.click_counts.create!( :count => 10, :created_at => Time.zone.now.yesterday - 8.days, :publisher_id => offer.publisher.id)
      offer.update_popularity!
      assert_equal 4.28, offer.popularity.to_f
    end
  end
  
  test "url_for_bit_ly uses configured path when publisher has a path format configured" do
    publishing_group = Factory(:publishing_group, :label => "mcclatchy")
    publisher = Factory(:publisher, :label => "sacbee", :publishing_group => publishing_group, :production_host => "sacbee.findnsave.com")
    advertiser = Factory(:advertiser, :publisher => publisher)
    offer = Factory(:offer, :advertiser => advertiser)
    
    assert_equal "http://sacbee.findnsave.com/Coupons?couponid=#{offer.id}", offer.url_for_bit_ly
  end

  test "url_for_bit_ly uses default path when publisher does not have a path format configured" do
    publisher = Factory(:publisher, :label => "xxxxxx", :production_host => "www.xxxxxx.com")
    advertiser = Factory(:advertiser, :publisher => publisher)
    offer = Factory(:offer, :advertiser => advertiser)
    
    assert_equal "http://www.xxxxxx.com/publishers/#{publisher.id}/offers?offer_id=#{offer.id}", offer.url_for_bit_ly
  end

  test "initialization of bit_ly_url when bit.ly gateway is down" do
    offer = Factory.build(:offer)

    BitLyGateway.instance.stubs(:shorten).returns nil
    offer.save!
    
    assert offer.bit_ly_url.blank?, "bit_ly_url should be blank if bit.ly gateway is down"
  end
  
  test "self_or_advertiser_or_store_last_updated_at" do
    Time.stubs(:now).returns(timestamp_1 = Time.parse("Dec 01, 2010 01:00:00"))
    advertiser = Factory(:advertiser, :name => "Old Name")
    assert_equal timestamp_1, advertiser.updated_at
    
    Time.stubs(:now).returns(timestamp_2 = Time.parse("Dec 01, 2010 02:00:00"))
    offer = Factory(:offer, :advertiser => advertiser)
    assert_equal timestamp_2, offer.updated_at
    assert_equal timestamp_2, offer.self_or_advertiser_or_store_last_updated_at
    
    Time.stubs(:now).returns(timestamp_3 = Time.parse("Dec 01, 2010 03:00:00"))
    advertiser.update_attributes! :name => "New Name"
    assert_equal timestamp_3, advertiser.updated_at
    assert_equal timestamp_2, offer.updated_at
    assert_equal timestamp_3, offer.self_or_advertiser_or_store_last_updated_at
    
    Time.stubs(:now).returns(timestamp_4 = Time.parse("Dec 01, 2010 04:00:00"))
    advertiser.store.update_attributes! :state => "CA"
    assert_equal timestamp_4, advertiser.store.updated_at
    assert_equal timestamp_3, advertiser.updated_at
    assert_equal timestamp_2, offer.updated_at
    assert_equal timestamp_4, offer.self_or_advertiser_or_store_last_updated_at    
  end

  test "syndicated scope" do
    publisher1 = Factory(:publisher, :offers_available_for_syndication => true)
    publisher2 = Factory(:publisher, :offers_available_for_syndication => false)

    offer1 = Factory(:offer)
    offer1.place_with(publisher1)
    offer2 = Factory(:offer)
    offer2.place_with(publisher2)

    syndicated_offers = Offer.syndicated

    assert syndicated_offers.include?(offer1)
    assert !syndicated_offers.include?(offer2)
  end

  fast_context "manageable_by" do
    fast_context "with manageable advertisers" do
      setup do
        @publisher1 = Factory(:publisher, :offers_available_for_syndication => true, :self_serve => true)
        @publisher2 = Factory(:publisher, :self_serve => true)

        @advertiser1 = Factory(:advertiser, :publisher => @publisher1)
        @advertiser2 = Factory(:advertiser, :publisher => @publisher2)
      end

      fast_context "without syndication" do
        should "return only offers from manageable advertisers" do
          user = Factory(:user, :company => @publisher2)

          offer1 = Factory(:offer, :advertiser => @advertiser1)
          offer2 = Factory(:offer, :advertiser => @advertiser2)

          assert !Offer.manageable_by(user).include?(offer1)
          assert Offer.manageable_by(user).include?(offer2)
        end
      end

      fast_context "with offer syndication" do
        should "return both syndicated and nonsyndicated offers" do
          user = Factory(:user, :company => @publisher2, :allow_offer_syndication_access => true)

          offer1 = Factory(:offer, :advertiser => @advertiser1)
          offer2 = Factory(:offer, :advertiser => @advertiser2)

          assert Offer.manageable_by(user).include?(offer1)
          assert Offer.manageable_by(user).include?(offer2)
        end
      end
    end

    fast_context "without manageable advertisers" do
      setup do
        @publisher1 = Factory(:publisher, :offers_available_for_syndication => true)
        @publisher2 = Factory(:publisher)

        @advertiser1 = Factory(:advertiser, :publisher => @publisher1)
        @advertiser2 = Factory(:advertiser, :publisher => @publisher2)
      end

      fast_context "without syndication" do
        should "return only offers from manageable advertisers" do
          user = Factory(:user, :company => @publisher2)

          offer1 = Factory(:offer, :advertiser => @advertiser1)
          offer2 = Factory(:offer, :advertiser => @advertiser2)

          assert !Offer.manageable_by(user).include?(offer1)
          assert !Offer.manageable_by(user).include?(offer2)
        end
      end

      fast_context "with offer syndication" do
        should "return both syndicated and nonsyndicated offers" do
          user = Factory(:user, :company => @publisher2, :allow_offer_syndication_access => true)

          offer1 = Factory(:offer, :advertiser => @advertiser1)
          offer2 = Factory(:offer, :advertiser => @advertiser2)

          assert Offer.manageable_by(user).include?(offer1)
          assert !Offer.manageable_by(user).include?(offer2)
        end
      end
    end
  end

  private
  
  def with_publisher_or_advertiser_limit(advertiser, limit)
    publisher = advertiser.publisher
    
    advertiser.reload.update_attributes! :active_coupon_limit => limit
    publisher.reload.update_attributes!  :active_coupon_limit => nil
    yield "advertiser limit #{limit}"

    advertiser.reload.update_attributes! :active_coupon_limit => nil
    publisher.reload.update_attributes!  :active_coupon_limit => limit
    yield "publisher limit #{limit}"
    
    advertiser.reload.update_attributes! :active_coupon_limit => limit
    publisher.reload.update_attributes!  :active_coupon_limit => limit
    yield "advertiser and publisher limit #{limit}"
  end
end

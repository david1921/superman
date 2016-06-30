#!/usr/bin/env script/runner

# Run script from RAILS_ROOT: ./test/system/coupons_search_test.rb -e nightly 100
#
# -e     : Rails environment. Defaults to development
# number : number of coupon requests to create. Defaults to 10
#
# development environment doesn't cache, so it's slow unless you modify config/environments/development.rb

require "test/system/system_test"

::CREATE_BIT_LY_URLS = false

# Offer counts greater than 1000 take a long time to set up data
class CouponsSearchTest < SystemTest
  def run
    begin
      setup_data
      find_with_categories
      find_with_advertiser_name_text
      find_with_category_name_text
      find_with_category_and_text
      find_with_radius
      find_with_categories_text_zip_radius
    ensure
      teardown_data
      puts "Done."
       if RUBY_PLATFORM["darwin"]
         `say "done"`
       end
    end
  end
  
  def find_with_categories
    publisher = @publishers.sample
    categories = publisher.offers(true).sample.categories.sample
    offers = nil
    realtime = Benchmark.realtime do
      search_request = SearchRequest.new( :publisher => publisher, :categories => categories )
      offers = Offer.find_all_for_publisher( search_request )
    end
    p "#{realtime} seconds: search for category '#{categories.full_name}' in #{count} offers and #{Category.count} categories. Found #{offers.size} offers."
  end
  
  def find_with_advertiser_name_text
    publisher = @publishers.sample
    text = publisher.advertisers(true).sample.name
    
    # Force inexact match
    text = text[0, text.length / 2].downcase
    
    offers = nil
    realtime = Benchmark.realtime do
      search_request = SearchRequest.new( :publisher => publisher, :text => text )
      offers = Offer.find_all_for_publisher( search_request )
    end
    p "#{realtime} seconds: search for advertiser name text '#{text}' in #{count} offers and #{Category.count} categories. Found #{offers.size} offers."
  end
  
  def find_with_category_name_text
    publisher = @publishers.sample
    text = publisher.offers(true).sample.categories.sample.name
    
    # Force inexact match
    text = text[0, text.length / 2].upcase
    
    offers = nil
    realtime = Benchmark.realtime do
      search_request = SearchRequest.new( :publisher => publisher, :text => text )
      offers = Offer.find_all_for_publisher( search_request )
    end
    p "#{realtime} seconds: search for category text '#{text}' in #{count} offers and #{Category.count} categories. Found #{offers.size} offers."
  end
  
  def find_with_category_and_text
    publisher = @publishers.sample
    offer = publisher.offers(true).sample
    categories = offer.categories.sample    
    text = offer.advertiser.name
    
    # Force inexact match
    text = text[0, text.length / 2].upcase
    
    offers = nil
    realtime = Benchmark.realtime do
      search_request = SearchRequest.new( :publisher => publisher, :categories => categories, :text => text )
      offers = Offer.find_all_for_publisher( search_request )
    end
    p "#{realtime} seconds: search for category '#{categories.full_name}' and advertiser name text '#{text}' in #{count} offers and #{Category.count} categories. Found #{offers.size} offers."
  end
  
  def find_with_radius
    publisher = @publishers.sample
    offer = publisher.offers(true).sample
    postal_code = offer.advertiser.store.zip
    
    offers = nil
    realtime = Benchmark.realtime do  
      search_request = SearchRequest.new( :publisher => publisher, :postal_code => postal_code, :radius => 10 )
      offers = Offer.find_all_for_publisher( search_request )
    end
    p "#{realtime} seconds: search for ZIP '#{postal_code}' within 10 miles in #{count} offers. Found #{offers.size} offers."
  end
  
  def find_with_categories_text_zip_radius
    publisher = @publishers.sample
    offer = publisher.offers(true).sample
    postal_code = offer.advertiser.store.zip
    categories = offer.categories
    text = offer.advertiser.name
    
    # Force inexact match
    text = text[0, text.length / 2].upcase
    
    offers = nil
    realtime = Benchmark.realtime do
      search_request = SearchRequest.new(
      :publisher => publisher, 
      :categories => categories, 
      :text => text, 
      :postal_code => postal_code,
      :radius => 50)
      offers = Offer.find_all_for_publisher( search_request )
    end
    p "#{realtime} seconds: search for category '#{categories.map(&:full_name). join(', ')}' and advertiser name text '#{text}' ZIP '#{postal_code}' within 50 miles in #{count} offers. Found #{offers.size} offers."
  end
  
  def setup_data
    @publishers = []
    4.times do |index|
      name = "Publisher #{Faker::Company.name}"
      label = name.downcase.gsub(" ", "-").gsub(",", "").gsub("'", "")
      @publishers << Publisher.create!(:name => name, :label => label, :do_strict_validation => false)
    end
    
    [
      "Automotive",
      "Automotive: Repairs & Service",
      "Automotive: Smog Check",
      "Automotive: Window Tinting",
      "Clubs",
      "Electronics",
      "Entertainment",
      "Everything Else",
      "Health & Beauty",
      "Health & Beauty: Body Treatments",
      "Health & Beauty: Dental Treatments",
      "Health & Beauty: Eye Treatments",
      "Health & Beauty: Hair Treatments",
      "Health & Beauty: Massage & Spa Treatments",
      "Health & Beauty: Medical Marijuana",
      "Health & Beauty: Tanning",
      "Health & Beauty: Waxing and Laser Hair Removal",
      "Health & Beauty: Weight Loss",
      "Restaurants",
      "Restaurants: Pacific Beach, Mission Beach & Ocean Beach",
      "Restaurants: North County",
      "Restaurants: La Jolla",
      "Restaurants: East County & State College",
      "Restaurants: Uptown & North Park",
      "Restaurants: Midway, Old Town & Mission Valley",
      "Restaurants: Downtown & Point Loma",
      "Restaurants: Clairemont, University City, Miramar Rd., Poway, Mira Mesa, Scripps Ranch & Kearny Mesa",
      "Restaurants: South Bay",
      "Retail",
      "Services",
      "Travel"
    ].each do |category_name|
      Category.valid_objects_from_names(category_name).each(&:save!)
    end
    
    if ZipCode.count < 20
      p "Warning: only #{ZipCode.count} ZIP codes found. Is the database's ZIP codes table populated?"
    end

    # Ensure each Publisher has at least one offer
    @publishers.each do |publisher|
      place_offer(publisher)
    end
    
    (count - @publishers.size).times do |index|
      place_offer(@publishers.sample)
      if index % 50 == 0
        p "Created #{index} offers"
      end
    end
    p "setup_data done"
  end
  
  def teardown_data
    Offer.destroy_all :created_at => Time.now.beginning_of_day
    Advertiser.destroy_all :created_at => Time.now.beginning_of_day
    Publisher.destroy_all :created_at => Time.now.beginning_of_day
    Placement.destroy_all :created_at => Time.now.beginning_of_day
    Category.destroy_all :created_at => Time.now.beginning_of_day
    Store.destroy_all :created_at => Time.now.beginning_of_day
  end
  
  private
  
  def place_offer(publisher)
    advertiser = publisher.advertisers.create! :name => "#{Faker::Company.name} #{Faker::Company.name}"
    
    zip = random_zip_code
    store = advertiser.stores.create(
              :zip => zip.zip, 
              :address_line_1 => Faker::Address.street_address, 
              :city => zip.city, 
              :state => zip.state
            )    
    store.save!
    advertiser.logger.debug("Create advertiser")
    advertiser.offers.create!(
      :message => Faker::Company.catch_phrase, 
      :categories => Category.all(:limit => (rand * 4) + 1, :order => "rand()")
    )
    advertiser.logger.debug("Created advertiser")
  end
  
  # select * from zip_codes order by rand() is very slow
  def random_zip_code
    @zip_code_ids ||= ZipCode.all(
                       :select => "id, city, state, zip", 
                       :conditions => [ "city not in (?) and state in (?)", ["APO", "FPO"], Addresses::Codes::US::STATE_CODES ]
                     ).map(&:id)
    ZipCode.find(@zip_code_ids.sample)
  end
end

CouponsSearchTest.new(ARGV).run

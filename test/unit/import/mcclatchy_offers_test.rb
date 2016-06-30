require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Import::McclatchyOffers::McclatchyOffersTest
module Import
  module McclatchyOffers

    class McclatchyOffersTest < ActiveSupport::TestCase

      fast_context "when parsing xml into offers" do

        setup do
          @simple_doc = <<-eos
            <?xml version="1.0" encoding="utf-8"?>
            <feed type="coupons" generated="2010-12-28T12:46:37Z" runDate="20101228" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <coupons>
                <coupon>
                  <couponId>32460395</couponId>
                  <startDate>2010-12-28T06:00:00Z</startDate>
                  <endDate>2011-01-04T05:59:00Z</endDate>
                  <expiryDate>01/03/2011</expiryDate>
                  <couponCode>122210WT</couponCode>
                  <title>Only $49.95</title>
                  <subtitle>Wow Great Price!</subtitle>
                  <details><![CDATA[Wow Really Really Great Price!]]></details>
                  <conditions />
                  <couponPhotoUrl></couponPhotoUrl>
                  <categories>
                    <category id="33904" name="Local Services">
                      <category categoryId="34021" name="Air Duct Cleaning"/>
                      <category categoryId="34022" name="Bong Water Cleansing"/>
                      <category categoryId="34023" name="Ruby Programming"/>
                    </category>
                    <category categoryId="34026" name="Foreign Services"/>
                  </categories>
                  <advertiser>
                    <listingId>742300</listingId>
                    <businessName>Midwest Air Care</businessName>
                    <businessWebUrl>http://midwestaircare.net</businessWebUrl>
                    <locations>
                      <location>
                        <address>
                          <addr1>6713 North Oak Trafficway</addr1>
                          <city>Gladstone</city>
                          <province>MO</province>
                        </address>
                        <phone>(866) 979-8993</phone>
                      </location>
                      <location>
                        <address>
                          <addr1>1516 E 23rd St S</addr1>
                          <addr2>Suite C</addr2>
                          <city>Independence</city>
                          <province>MO</province>
                          <lat>39.0785</lat>
                          <lon>-94.3951</lon>
                        </address>
                        <phone>(866) 979-8993</phone>
                      </location>
                      <location>
                        <address>
                          <addr1>123 NE F St</addr1>
                          <city>Vancouver</city>
                          <province>WA</province>
                        </address>
                        <phone>123 456</phone>
                      </location>
                      <location>
                        <address>
                          <addr1>93 NW 43nd St</addr1>
                          <city>Portland</city>
                          <province>OR</province>
                        </address>
                        <phone>434-2939</phone>
                      </location>
                   </locations>
                  </advertiser>
                </coupon>
              </coupons>
            </feed>
          eos

          @publisher = Factory(:publisher,
                               :allow_seven_digit_advertiser_phone_numbers => true,
                               :do_strict_validation => false)
        end

        fast_context "when advertiser is new" do

          setup do
            @importer = McclatchyOffersImporter.new(@publisher, @simple_doc).parse_and_save_offers!
            @offer = @importer.offers[0]            
          end

          should "parse the right number of offers" do
            assert_equal 1, @importer.offers.size
          end

          should "parse and assign the start date properly" do
            assert_equal Time.utc(2010, 12, 28, 6, 0), @offer.show_on
          end

          should "parse and assign expires on properly" do
            assert_equal Time.utc(2011, 1, 4, 5, 59), @offer.expires_on
          end

          should "parse and assign coupon code properly" do
            assert_equal "122210WT", @offer.coupon_code
          end

          should "parse and assign terms properly" do
            assert_equal "Wow Really Really Great Price!", @offer.terms
          end

          should "parse and assign txt_message properly in case advertiser requires it" do
            assert_equal "Only $49.95", @offer.txt_message
          end

          should "parse and assign message properly" do
            assert_equal "Only $49.95", @offer.message
          end

          should "parse and assign value_proposition properly" do
            assert_equal "Only $49.95", @offer.value_proposition
          end

          should "parse and assign value_proposition_sub properly" do
            assert_equal "Wow Great Price!", @offer.value_proposition_detail
          end

          should "assign publisher to advertisers" do
            assert_equal @publisher, @offer.advertiser.publisher
          end

          should "create and assign advertiser with correct name" do
            assert_equal "Midwest Air Care", @offer.advertiser.name
          end

          should "create and assign advertiser with correct website_url" do
            assert_equal "http://midwestaircare.net", @offer.advertiser.website_url
          end
          
          should "create and assign advertiser with coupon clipping mode = [:email]" do
            assert @offer.advertiser.coupon_clipping_modes.include?(:email)
          end

          should "create stores for each location for advertiser" do
            assert_equal 4, @offer.advertiser.stores.size
          end

          should "correctly assign address_line_1 for a store" do
            assert_equal "6713 North Oak Trafficway", @offer.advertiser.stores[0].address_line_1
          end

          should "correctly assign address_line_12for a store" do
            assert_equal "Suite C", @offer.advertiser.stores[1].address_line_2
          end

          should "assign city to store" do
            assert_equal "Gladstone", @offer.advertiser.stores[0].city
          end

          should "assign state to store" do
            assert_equal "MO", @offer.advertiser.stores[0].state
          end

          should "assign phone to store" do
            assert_equal "18669798993", @offer.advertiser.stores[0].phone_number
          end

          should "assign latitude to store" do
            assert_equal 39.0785, @offer.advertiser.stores[1].latitude
          end

          should "assign longitude to store" do
            assert_equal -94.3951, @offer.advertiser.stores[1].longitude
          end

          should "not assign lat/long via geocoding if not specified" do
            assert_in_delta  45.5381, @offer.advertiser.stores[0].latitude, 0.001
            assert_in_delta -121.567, @offer.advertiser.stores[0].longitude, 0.001
          end

          should "create and assign the category names properly" do
            assert_equal "Foreign Services, Local Services: Air Duct Cleaning, Local Services: Bong Water Cleansing, Local Services: Ruby Programming", @offer.category_names
          end

          fast_context "parsed offer is saved and found again" do

            setup do
              @offer.save!
              @offer = Offer.find(@offer.id)
            end

            should "create saved offer with proper category names" do
              category_names = @offer.category_names.split(",").map { |c| c.split(":").map(&:strip) }.flatten.uniq
              assert category_names.include?("Local Services")
              assert category_names.include?("Air Duct Cleaning")
              assert category_names.include?("Bong Water Cleansing")
              assert category_names.include?("Ruby Programming")
              assert category_names.include?("Foreign Services")
              assert_equal 5, category_names.size
            end

            should "create matching categories in the database with the correct parent/child relationships" do
              local_services = Category.find_by_name("Local Services")
              assert_not_nil local_services
              assert_equal 3, local_services.children.size
              air_duct_cleaning = Category.find_by_name("Air Duct Cleaning")
              assert_not_nil air_duct_cleaning
              assert_equal local_services, air_duct_cleaning.parent
              ruby_programming = Category.find_by_name("Ruby Programming")
              assert_not_nil ruby_programming
              assert_equal local_services, ruby_programming.parent
            end

            should "have an advertiser" do
              assert_not_nil @offer.advertiser
            end

            should "be able to access the publisher" do
              assert_equal @publisher, @offer.publisher
            end

            should "be able to find the advertiser" do
              assert_not_nil ::Advertiser.find_by_publisher_id_and_name(@publisher.id, "Midwest Air Care")
            end
          end

        end

        fast_context "when advertiser already exists" do

          setup do
            @advertiser = Factory(:advertiser, :publisher => @publisher, :name => "Midwest Air Care", :stores => [])
            @importer = McclatchyOffersImporter.new(@publisher, @simple_doc).parse_and_save_offers!
            @offer = @importer.offers[0]
          end

          should "offer should use the existing advertiser and not make a new one" do
            assert_equal @publisher, @offer.advertiser.publisher
            assert_equal @advertiser, @offer.advertiser
          end

          should "have 4 stores because we should have used the locations in the xml to update them" do
            assert_equal 4, @offer.advertiser.stores.size
          end

        end

        fast_context "when publisher requires offers to have listings" do

          setup do
            @publisher = Factory(:publisher, :offer_has_listing => true)
            @advertiser = Factory(:advertiser, :publisher => @publisher, :name => "Midwest Air Care", :stores => [])
            @importer = McclatchyOffersImporter.new(@publisher, @simple_doc).parse_and_save_offers!
            @offer = @importer.offers[0]
          end

          should "be a valid offer" do
            assert @offer.valid?
          end

        end

      end
    end
  end
end

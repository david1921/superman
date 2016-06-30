require File.dirname(__FILE__) + "/../test_helper"

class GoogleOffersFeedExportTest < ActiveSupport::TestCase

  context "#export_google_offers_feed_xml! for ocregister" do

    setup do
      Timecop.freeze(Time.zone.local(2011, 8, 13, 12, 34, 56)) do
        @publishing_group = Factory :publishing_group, :label => "freedom"
        @publisher = Factory :publisher, :label => "ocregister", :publishing_group => @publishing_group
        @advertiser_1 = Factory :advertiser, :name => "the first advertiser", :publisher => @publisher,
                                :description => "first advertiser's description"
        @advertiser_2 = Factory :advertiser, :name => "the second advertiser", :publisher => @publisher,
                                :website_url => "http://example.com/adv1", :description => "second advertiser's description"
        Factory :store, :address_line_1 => "100 Test Road", :address_line_2 => "", :city => "Testville", :state => "TX",
                :zip => "90210", :phone_number => "2025551234", :advertiser => @advertiser_2
        @advertiser_2.stores.reload
        @old_deal = Factory :daily_deal, :advertiser => @advertiser_1, :start_at => 3.months.ago, :hide_at => 2.months.ago
        @deal_1 = Factory :side_daily_deal, :value_proposition => "awesome deal 1", :advertiser => @advertiser_1,
                          :start_at => 2.days.ago, :hide_at => 9.days.from_now,
                          :description => "deal desc 1", :price => 19, :value => 35,
                          :quantity => 1200, :expires_on => 1.year.from_now, :highlights => "* first highlight\n*second highlight\n\n\nthird highlight",
                          :terms => "some terms here", :voucher_steps => "1. first do this\n2. then do this",
                          :location_required => false
        @deal_2 = Factory :daily_deal, :value_proposition => "awesome deal 2", :advertiser => @advertiser_2,
                          :start_at => 1.week.ago, :hide_at => 2.weeks.from_now,
                          :description => "deal desc 2\na second line", :price => 11.22, :value => 25.42,
                          :quantity => nil, :terms => "* offer valid only sometimes\n* just kidding\n* three\n*four\nfive\nsix\nseven\neight\nnine\nten.\neleven\n* twelve",
                          :voucher_steps => "1. step one\n2. step two", :location_required => false
        @deal_3 = Factory :side_daily_deal, :value_proposition => "awesome deal which requires a location", :advertiser => @advertiser_2,
                          :start_at => 4.days.ago, :hide_at => 9.hours.from_now, :location_required => true
        
        @export_buffer = ""
        @publisher.export_google_offers_feed_xml!(@export_buffer)
        @xml_doc = Nokogiri::XML(@export_buffer)
        @first_deal, @second_deal = @xml_doc.css("entry")
      end
    end

    context "the export" do

      should "export to a file in the Rails tmp directory" do
        Timecop.freeze(Time.zone.local(2011, 8, 13, 12, 34, 56)) do
          assert_match %r{#{Rails.root.join("tmp")}/ocregister-google-feed-20110813123456.xml}, @publisher.google_offers_feed_xml_filename
        end
      end
      
      should "set the top-level feed namespace correctly" do
        feed = @xml_doc.root
        assert_equal "feed", feed.name
        assert_equal 1, feed.attributes.size
        assert_equal "en-US", feed.attributes["lang"].content
        assert_equal "http://base.google.com/ns/1.0", feed.namespace.href
      end

      should "include N entries, where N == the publisher's number of current or future deals " +
             "*excluding* deals that require a location" do
        assert_equal 2, @xml_doc.css("feed entry").size, @xml_doc.inspect
      end

      should "set <id> to the deal UUID" do
        ids = @xml_doc.css("feed entry id")
        assert_equal @deal_1.uuid, ids[0].text
        assert_equal @deal_2.uuid, ids[1].text
      end

      should "set <type> to marketplace_prepaid" do
        mps = @xml_doc.css("feed entry type")
        assert_equal "marketplace_prepaid", mps[0].text
        assert_equal "marketplace_prepaid", mps[1].text
      end

      should "set <title> to the value proposition" do
        titles = @xml_doc.css("feed entry title")
        assert_equal "awesome deal 1", titles[0].text
        assert_equal "awesome deal 2", titles[1].text
      end

      should "set <description> to the deal description" do
        descs = @xml_doc.css("feed entry > description")
        assert descs[0].children[0].cdata?
        assert descs[1].children[0].cdata?
        assert_equal "deal desc 1", descs[0].children[0].text
        assert_equal "deal desc 2<br>a second line", descs[1].children[0].text
      end

      should "set <display_image> to the deal photo url" do
        urls = @xml_doc.css("feed entry display_image")
        assert_equal @deal_1.photo.url, urls[0].text
        assert_equal @deal_2.photo.url, urls[1].text
      end

      should "set <attribution_image> to the publisher logo" do
        att_images = @xml_doc.css("feed entry attribution_image")
        assert_equal @deal_1.publisher.logo.url, att_images[0].text
        assert_equal @deal_2.publisher.logo.url, att_images[1].text
      end

      should "create a <highlight> for each deal highlight specified" do
        highlights = @first_deal.css("highlight")
        assert_equal 3, highlights.size
        assert_equal "first highlight", highlights[0].text
        assert_equal "second highlight", highlights[1].text
        assert_equal "third highlight", highlights[2].text
      end

      should "NOT create any <highlight> elements when the deal has no highlights" do
        assert @second_deal.css("highlight").blank?
      end

      should "create a <fine_print> for each deal fine print item, maximum 10 (excess is concatenated to last element)" do
        fine_prints = @xml_doc.css("feed entry fine_print")
        assert_equal 11, fine_prints.size
        assert_equal "some terms here", fine_prints[0].text
        assert_equal "offer valid only sometimes", fine_prints[1].text
        assert_equal "just kidding", fine_prints[2].text
        assert_equal "three", fine_prints[3].text
        assert_equal "four", fine_prints[4].text
        assert_equal "five", fine_prints[5].text
        assert_equal "six", fine_prints[6].text
        assert_equal "seven", fine_prints[7].text
        assert_equal "eight", fine_prints[8].text
        assert_equal "nine", fine_prints[9].text
        assert_equal "ten. eleven. twelve", fine_prints[10].text
      end
      
      should "set <original_price> to the deal value" do
        prices = @xml_doc.css("feed entry original_price")
        assert_equal "35.00 USD", prices[0].text
        assert_equal "25.42 USD", prices[1].text
      end

      should "set <offer_price> to the deal price" do
        prices = @xml_doc.css("feed entry offer_price")
        assert_equal "19.00 USD", prices[0].text
        assert_equal "11.22 USD", prices[1].text
      end

      should "set <max_available> to the deal quantity, or 100000 if not quantity specified" do
        maxes = @xml_doc.css("feed entry max_available")
        assert_equal "1200", maxes[0].text
        assert_equal "100000", maxes[1].text
      end

      should "set <max_allow_user> to the deal max purchase quantity" do
        maxes = @xml_doc.css("feed entry max_allow_user")
        assert_equal "10", maxes[0].text
        assert_equal "10", maxes[1].text
      end

      should "set <distribution_date> to start_at/hide_at in ISO 8601 format" do
        dist_dates = @xml_doc.css("feed entry distribution_date")
        assert_equal "2011-08-11T12:34:56-07:00/2011-08-22T12:34:56-07:00", dist_dates[0].text
        assert_equal "2011-08-06T12:34:56-07:00/2011-08-27T12:34:56-07:00", dist_dates[1].text
      end

      should "set <redemption_date> to start_at/expires_on, when expires_on is set" do
        red_dates = @xml_doc.css("feed entry redemption_date")
        assert_equal 1, red_dates.size
        assert_equal "2011-08-11T12:34:56-07:00/2012-08-13T23:59:59-07:00", red_dates[0].text
      end

      context "merchant details" do

        setup do
          @merchants = @xml_doc.css("feed entry merchant")
        end

        should "include 1 <merchant> element" do
          assert_equal 2, @merchants.size
        end

        should "set <name> to the advertiser name" do
          names = @merchants.css("name")
          assert_equal "the first advertiser", names[0].text
          assert_equal "the second advertiser", names[1].text
        end

        should "include the <description> (we don't have an equivalent value)" do
          descriptions = @merchants.css("description")
          assert_equal 2, descriptions.size
          assert_equal "first advertiser's description", descriptions[0].text
          assert_equal "second advertiser's description", descriptions[1].text
        end

        should "set <url> to the merchant URL" do
          urls = @merchants.css("url")
          assert_equal 1, urls.size
          assert_equal "http://example.com/adv1", urls[0].text
        end

      end
      
      context "merchant location" do
        
        setup do
          @merchant_locations = @xml_doc.css("entry > merchant_location")
        end
        
        should "export one location per entry" do
          assert_equal 2, @merchant_locations.size
        end
        
        should "set <address_1> to store.address_line_1" do
          addr_1s = @merchant_locations.css("address_1")
          assert_equal "3005 South Lamar", addr_1s[0].text
          assert_equal "3005 South Lamar", addr_1s[1].text
        end
                   
        should "set <address_2> to store.address_line_2, if present" do
          addr_2s = @merchant_locations.css("address_2")
          assert_equal "Apt 1", addr_2s[0].text
          assert_equal "Apt 1", addr_2s[1].text
        end
                   
        should "set <city> to store.city" do
          cities = @merchant_locations.css("city")
          assert_equal "Austin", cities[0].text
          assert_equal "Austin", cities[1].text
        end
        
        should "set <state> to store.state" do
          states = @merchant_locations.css("state")
          assert_equal "TX", states[0].text
          assert_equal "TX", states[1].text
        end
        
        should "set <postal_code> to store.zip" do
          zips = @merchant_locations.css("postal_code")
          assert_equal "78704", zips[0].text
          assert_equal "78704", zips[1].text
        end
        
        should "set <country_code> to store.country.code" do
          country_codes = @merchant_locations.css("country_code")
          assert_equal "US", country_codes[0].text
          assert_equal "US", country_codes[1].text
        end
        
        should "set <phone> to store.phone_number" do
          phones = @merchant_locations.css("phone")
          assert_equal "15124161500", phones[0].text
          assert_equal "15124161500", phones[1].text
        end
        
      end

      context "redemption information" do

        setup do
          @redemptions = @xml_doc.css("feed entry redemption")
        end

        should "be specified in the <redemption> element" do
          assert_equal 2, @redemptions.size
        end

        should "set <code_provider_type> to google" do
          cpts = @redemptions.css("code_provider_type")
          assert_equal 2, cpts.length
          assert_equal "google", cpts[0].text
          assert_equal "google", cpts[1].text
        end

        should "set <code_display_type> to alphanumeric" do
          cdts = @redemptions.css("code_display_type")
          assert_equal 2, cdts.size
          assert_equal "alphanumeric", cdts[0].text
          assert_equal "alphanumeric", cdts[1].text
        end

        should "specify the <instructions> element" do
          insts = @redemptions.css("instructions")
          assert_equal 2, insts.size
          assert insts[0].children[0].cdata?
          assert insts[1].children[0].cdata?
          assert_equal "1. first do this<br>2. then do this", insts[0].children[0].text
          assert_equal "1. step one<br>2. step two", insts[1].children[0].text
        end

        context "redemption locations" do

          setup do
            @locations = @xml_doc.css("entry > redemption_location")
          end

          should "include N <redemption_location>'s, where N == number of merchant locations" do
            assert_equal 3, @locations.size
          end

          should "set <address1> to the store address_line_1" do
            add1s = @locations.css("address_1")
            assert_equal 3, add1s.size
            assert_equal "3005 South Lamar", add1s[0].text
            assert_equal "3005 South Lamar", add1s[1].text
            assert_equal "100 Test Road", add1s[2].text
          end

          should "set <address2> to the store address_line_2" do
            add2s = @locations.css("address_2")
            assert_equal 2, add2s.size
            assert_equal "Apt 1", add2s[0].text
            assert_equal "Apt 1", add2s[1].text
          end

          should "set <city> to the store city" do
            cities = @locations.css("city")
            assert_equal 3, cities.size
            assert_equal "Austin", cities[0].text
            assert_equal "Austin", cities[1].text
            assert_equal "Testville", cities[2].text
          end

          should "set <state> to the store state" do
            states = @locations.css("state")
            assert_equal 3, states.size
            assert_equal "TX", states[0].text
            assert_equal "TX", states[1].text
            assert_equal "TX", states[2].text
          end

          should "set <postal_code> to the store zip" do
            zips = @locations.css("postal_code")
            assert_equal 3, zips.size
            assert_equal "78704", zips[0].text
            assert_equal "78704", zips[1].text
            assert_equal "90210", zips[2].text
          end

          should "set <country_code> to the store country code" do
            countries = @locations.css("country_code")
            assert_equal 3, countries.size
            assert_equal "US", countries[0].text
            assert_equal "US", countries[1].text
            assert_equal "US", countries[2].text
          end

          should "set <phone> to the store phone" do
            phones = @locations.css("phone")
            assert_equal 3, phones.size
            assert_equal "15124161500", phones[0].text
            assert_equal "15124161500", phones[1].text
            assert_equal "12025551234", phones[2].text
          end

          should "NOT include an <email> element (we don't have an equivalent value)" do
            assert @locations.css("email").blank?
          end

        end

      end

    end

  end
  
  context "#enable_google_offers_feed?" do
    
    should "return true if publisher label == 'ocregister'" do
      p = Factory :publisher, :label => "ocregister"
      assert p.enable_google_offers_feed?
    end
    
    should "return false if publisher label != 'ocregister'" do
      p = Factory :publisher, :label => "not-ocregister"
      assert !p.enable_google_offers_feed?
    end
    
  end

end

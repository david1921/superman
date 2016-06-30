require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealHelperTest < ActionView::TestCase
  test "daily_deal_how_it_works all blank" do
    publishing_group = Factory.stub(:publishing_group, :how_it_works => "")
    publisher = Factory.stub(:publisher, :publishing_group => publishing_group)
    assert_equal "", daily_deal_how_it_works(publisher), "how_it_works"
  end
  
  test "daily_deal_how_it_works should use publisher's value" do
    publisher = Factory.stub(:publisher, :how_it_works => "sometimes")
    assert_equal "<p>sometimes</p>", daily_deal_how_it_works(publisher), "how_it_works"
  end
  
  test "daily_deal_how_it_works should use publisher's value if publishing_group's value is blank" do
    publishing_group = Factory.stub(:publishing_group, :how_it_works => nil)
    publisher = Factory.stub(:publisher, :publishing_group => publishing_group, :how_it_works => "sometimes")
    assert_equal "<p>sometimes</p>", daily_deal_how_it_works(publisher), "how_it_works"
  end
  
  test "daily_deal_how_it_works should use publishing_group's value" do
    publishing_group = Factory.stub(:publishing_group, :how_it_works => "Works great")
    publisher = Factory.stub(:publisher, :publishing_group => publishing_group)
    assert_equal "<p>Works great</p>", daily_deal_how_it_works(publisher), "how_it_works"
  end
  
  test "publisher's value should override publishing_groups's value for daily_deal_how_it_works" do
    publishing_group = Factory.stub(:publishing_group, :how_it_works => "Works great")
    publisher = Factory.stub(:publisher, :publishing_group => publishing_group, :how_it_works => "sometimes")
    assert_equal "<p>sometimes</p>", daily_deal_how_it_works(publisher), "how_it_works"
  end
  
  test "daily deal page title with no slug and no publisher" do
    assert_equal "Deal of the Day", daily_deal_page_title, "No publisher, no slug"
  end
  
  test "daily deal page title with no slug and publisher with no daily deal" do
    @publisher = publishers(:dallas_observer)
    assert_equal 0, @publisher.daily_deals.count, "Fixture should not have any daily deals"
    assert_equal "Deal of the Day: Dallas Observer", daily_deal_page_title, "Publisher, no daily deal, no slug"
  end

  test "daily deal page title with no slug and publisher daily deal with no short description" do
    daily_deal = daily_deals(:burger_king)
    daily_deal.update_attributes! :short_description => nil
    @publisher = daily_deal.publisher
    assert_equal "Deal of the Day: MySpace", daily_deal_page_title
  end

  test "daily deal page title with no slug and publisher daily deal with short description" do
    daily_deal = daily_deals(:burger_king)
    @publisher = daily_deal.publisher
    assert_equal "Today's deal from Burger King - Deal of the Day: MySpace", daily_deal_page_title
  end

  test "daily deal page title with slug and publisher daily deal with short description" do
    daily_deal = daily_deals(:burger_king)
    @publisher = daily_deal.publisher
    @daily_deal_page_title_slug = "Sign In"
    assert_equal "Today's deal from Burger King - Sign In - Deal of the Day: MySpace", daily_deal_page_title
  end
  
  test "truncate_textiled should return the original value, rendered as HTML when no truncation is required" do
    daily_deal = Factory(:daily_deal, :highlights => "We offer *the* best deals in the land")
    assert_equal "<p>We offer <strong>the</strong> best deals in the land</p>",
                 truncate_textiled(daily_deal.highlights(:source), :length => 100)
  end
  
  test "truncate_textiled should truncate the textile source, and render truncated value as HTML markup " +
       "when truncation is required" do
    daily_deal = Factory(:daily_deal, :highlights => "We offer *the* best deals in the land")
    assert_equal "<p>We offer <strong>the</strong> be&#8230;</p>",
                 truncate_textiled(daily_deal.highlights(:source), :length => 20)
  end
  
  test "get_dollars_and_cents should return an array with two items: the dollar and cent values of a given number" do
    assert_equal(["42", "00"], get_dollars_and_cents(42))
    assert_equal(["42", "00"], get_dollars_and_cents(42.00))
    assert_equal(["42", "18"], get_dollars_and_cents(42.18))
  end
  
  test "all_publisher_labels_as_autocomplete_source should return a string suitable for a jquery ui autocomplete source" do
    autocomplete_source = all_publisher_labels_as_autocomplete_source
    assert autocomplete_source.is_a?(String)
    assert_no_match /autocomplete-meplease/, autocomplete_source
    
    Factory :publisher, :label => "autocomplete-meplease"
    autocomplete_source = all_publisher_labels_as_autocomplete_source
    assert_match /autocomplete-meplease/, autocomplete_source
  end
  
  test "affiliated_publishers_for" do
    affiliated_pub = Factory :publisher, :label => "some-affiliate"
    daily_deal = Factory :daily_deal
    
    assert_match /No affiliates/, affiliated_publishers_for(daily_deal)
    Factory :affiliate_placement, :affiliate => affiliated_pub, :placeable => daily_deal
    affiliates_ul = affiliated_publishers_for(daily_deal.reload)
    assert_match /<ul id="affiliate-placements">/, affiliates_ul
    assert_match %r{<a href="/publishers/#{affiliated_pub.id}/edit".*>some-affiliate</a>}, affiliates_ul
  end

  test "#options_for_email_voucher_offer" do
    #TODO: this test could be better, but I don't have time right now
    dd = Factory(:daily_deal)
    offer = Factory(:offer, :advertiser => dd.advertiser)
    expired_offer = Factory(:offer, :advertiser => dd.advertiser, :expires_on => 1.day.ago)
    dd.email_voucher_offer = expired_offer
    dd.save!
    options = options_for_email_voucher_offer(dd)
    assert_equal [[email_voucher_offer_option_text(expired_offer), expired_offer.id], [email_voucher_offer_option_text(offer), offer.id]], options
  end

  test "#email_voucher_offer_option_text" do
    offer = Factory(:offer, :expires_on => nil, :show_on => nil, :message => msg = "50% widgets")
    assert_equal "#{msg} (now => forever)", email_voucher_offer_option_text(offer)
    offer.show_on = 1.week.ago
    offer.expires_on = 1.week.from_now
    assert_equal "#{msg} (#{offer.show_on} => #{offer.expires_on})", email_voucher_offer_option_text(offer)
  end

  test "#daily_deal_cancel_link should include a market if there is a market in the params" do
    publisher = Factory.create(:publisher)
    @params = { :label => publisher.label, :market_label => "chicago" }
    assert_equal %Q{<a href="/publishers/#{publisher.label}/chicago/deal-of-the-day" id="cancel_link">Cancel</a>}, daily_deal_cancel_link(publisher)
  end

  test "#daily_deal_cancel_link should not include a market if there is not a market in the params" do
    publisher = Factory.create(:publisher)
    @params = { :label => publisher.label }
    assert_equal %Q{<a href="/publishers/#{publisher.label}/deal-of-the-day" id="cancel_link">Cancel</a>}, daily_deal_cancel_link(publisher)
  end
  
  test "#daily_deal_cancel_link should be set to custom cancel url if it is set" do
    publisher = Factory.create(:publisher, :custom_cancel_url => "http://www.couponcity.gr/category")
    assert_equal %Q{<a href="http://www.couponcity.gr/category" id="cancel_link">Cancel</a>}, daily_deal_cancel_link(publisher)
  end
  
  context "formatted_price_for" do
    
    should "return an empty string if there is no price" do
      assert_equal "", formatted_price_for("")
    end
    
    should "return a price without a decimal when non-fractional" do
      price = 12.00
      assert_equal "$12", formatted_price_for(price)
    end
    
    should "return a price with a decimal when fractional" do
      price = 12.25
      assert_equal "<span class='deal_fractional_price'>$12.25</span>", formatted_price_for(price)
    end

    should "return a price with the currency symbol passed in" do
      price = 12.35
      assert_equal "<span class='deal_fractional_price'>€12.35</span>", formatted_price_for(price, '€')
    end
    
  end
  
  context "#email_voucher_redemption_message_for_this_exact_locale" do
    
    setup do
      @daily_deal = Factory :daily_deal
      hack_to_load_translations_association(@daily_deal)
      assert_equal 1, @daily_deal.translations.size
      assert_equal :en, @daily_deal.translations.first.locale
    end
    
    should "return a non-blank string when there is a translation of email_voucher_redemption_message " +
           "for the current locale specifically" do
      I18n.locale = :en
      assert email_voucher_redemption_message_for_this_exact_locale(@daily_deal).present?
    end

    should "return nil when there is no translation of email_voucher_redemption_message for the" +
           "current locale specifically" do
      I18n.locale = "es-MX"
      assert_nil email_voucher_redemption_message_for_this_exact_locale(@daily_deal)
    end
    
  end
  
  context "apple_app_store_url(publisher)" do
    
    setup do
      @publisher = Factory :publisher
    end
    
    should "return the publisher's apple app store url, if present" do
      @publisher.apple_app_store_url = "http://test.app.url"
      assert_equal "http://test.app.url", apple_app_store_url(@publisher)
    end
    
    should "return the publishing group's apple app store url, if present and the publisher's is blank" do
      @publisher.publishing_group.apple_app_store_url = "http://test.group.app.url"
      assert_equal "http://test.group.app.url", apple_app_store_url(@publisher)
    end
    
    should "return nil if the publisher and pub group's apple app store url is blank" do
      assert_nil @publisher.apple_app_store_url
      assert_nil @publisher.publishing_group.apple_app_store_url
      assert_nil apple_app_store_url(@publisher)
    end

  end

  context "category deal sorting" do
    setup do
      @publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)
      @category  = Factory(:daily_deal_category, :name => "Deal 1", :publishing_group_id => @publisher.publishing_group.id)
      @category1 = Factory(:daily_deal_category, :name => "Deal 2", :publishing_group_id => @publisher.publishing_group.id)
      @category2 = Factory(:daily_deal_category, :name => "Deal 10", :publishing_group_id => @publisher.publishing_group.id)
      @deal1 = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category_id => @category1.id)
      @deal2 = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category_id => @category2.id)
      @deal3 = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category_id => @category.id)
      @deal4 = Factory(:side_daily_deal, :publisher => @publisher)
      @deal5 = Factory(:daily_deal, :publisher => @publisher)
    end

    context "#category_deals_only_for" do
      should "return only deals with publisher_category_id set" do
        assert_same_elements [@deal1, @deal2, @deal3], category_deals_only_for(@publisher.daily_deals)
      end
    end

    context "#remove_category_deals_from" do
      should "return deals that do not have publisher_category_id set" do
        assert_same_elements [@deal4, @deal5], remove_category_deals_from(@publisher.daily_deals)
      end
    end
  end

  context "#hours_or_days_remaining_from_now" do
    should "return in days with from time of 48 hours from now" do
      Timecop.freeze(Time.zone.local(2012,1,1,12,0,0)) do
        assert_equal "2 days", hours_or_days_remaining_from_now(48.hours.from_now)
      end
    end
    should "in hours with from time of 23.4 hours from now" do
      Timecop.freeze(Time.zone.local(2012,1,1,12,0,0)) do
        assert_equal "23 hours", hours_or_days_remaining_from_now((23.4).hours.from_now)
      end
    end
    should "return in days with from time of 36 hours from now" do
      Timecop.freeze(Time.zone.local(2011,12,31,12,0,0)) do
        assert_equal "2 days", hours_or_days_remaining_from_now(36.hours.from_now)
      end
    end
    should "return nil with nil time passed" do
      assert_nil hours_or_days_remaining_from_now(nil)
    end

    context "with the es locale" do
      setup do
        @previous_locale = I18n.locale
        I18n.locale = :es
      end

      teardown do
        I18n.locale = @previous_locale
      end

      should "return plural localized version of day with from time of 48 hours from now" do
        Timecop.freeze(Time.zone.local(2012,1,1,12,0,0)) do
          assert_equal "2 días", hours_or_days_remaining_from_now(48.hours.from_now)
        end
      end

      should "return singular localized version day with from time of 24 hours from now" do
        Timecop.freeze(Time.zone.local(2012,1,1,12,0,0)) do
          assert_equal "1 día", hours_or_days_remaining_from_now(24.hours.from_now)
        end
      end

      should "return plural localized version of hour with from time of 23.4 hours from now" do
        Timecop.freeze(Time.zone.local(2012,1,1,12,0,0)) do
          assert_equal "23 horas", hours_or_days_remaining_from_now((23.4).hours.from_now)
        end
      end

      should "return singular localized version of hour with from time of 1 hour from now" do
        Timecop.freeze(Time.zone.local(2012,1,1,12,0,0)) do
          assert_equal "1 hora", hours_or_days_remaining_from_now(1.hour.from_now)
        end
      end
    end
  end
  
  context "loyalty_program_url(daily_deal, referrer)" do
    
    should "return the URL used for the loyalty program on a deal, using the publisher's daily deal host" do
      consumer = Factory :consumer, :referrer_code => "ABC123"
      deal = Factory :daily_deal, :publisher => consumer.publisher
      deal.publisher.update_attribute :production_daily_deal_host, "wickeddeals.com"
      assert_equal "http://wickeddeals.com/daily_deals/#{deal.id}?referral_code=ABC123", loyalty_program_url(deal, consumer)
    end
    
    should "return the loyalty URL when the consumer belongs to another publisher in this " +
           "publishing group, and the group allows single sign-on" do
      pub_group = Factory :publishing_group, :allow_single_sign_on => true, :unique_email_across_publishing_group => true
      publisher_1 = Factory :publisher, :publishing_group => pub_group, :production_daily_deal_host => "wickeddeals.com"
      publisher_2 = Factory :publisher, :publishing_group => pub_group, :production_daily_deal_host => "otherpub.example.com"
      deal = Factory :daily_deal, :publisher => publisher_1
      consumer = Factory :consumer, :referrer_code => "ABC123", :publisher => publisher_2

      assert_equal "http://wickeddeals.com/daily_deals/#{deal.id}?referral_code=ABC123", loyalty_program_url(deal, consumer)
    end
    
    should "raise an exception when the consumer belongs to another publisher in this " +
           "publishing group, and the group does *not* allow single sign-on" do
      pub_group = Factory :publishing_group, :allow_single_sign_on => false
      publisher_1 = Factory :publisher, :publishing_group => pub_group, :production_daily_deal_host => "wickeddeals.com"
      publisher_2 = Factory :publisher, :publishing_group => pub_group, :production_daily_deal_host => "otherpub.example.com"
      deal = Factory :daily_deal, :publisher => publisher_1
      consumer = Factory :consumer, :referrer_code => "ABC123", :publisher => publisher_2
      
      begin
        loyalty_program_url(deal, consumer)
      rescue RuntimeError => e
        assert_equal "can't generate loyalty program url: this consumer belongs to a different publisher", e.message
      else
        assert false, "should have raised an exception"
      end
    end
           
    should "raise an exception when the consumer belongs to a publisher in a completely different group, " +
           "even if the deal's publishing group allows single sign-on" do
      pub_group = Factory :publishing_group, :allow_single_sign_on => true, :unique_email_across_publishing_group => true
      publisher_1 = Factory :publisher, :publishing_group => pub_group, :production_daily_deal_host => "wickeddeals.com"
      deal = Factory :daily_deal, :publisher => publisher_1
      consumer = Factory :consumer, :referrer_code => "ABC123"
      
      begin
        loyalty_program_url(deal, consumer)
      rescue RuntimeError => e
        assert_equal "can't generate loyalty program url: this consumer belongs to a different publisher", e.message
      else
        assert false, "should have raised an exception"
      end
    end
    
    should "raise an exception when the consumer belongs to a publisher different than the deal, " +
           "and the deal's publisher has no publishing group" do
      publisher_1 = Factory :publisher, :publishing_group => nil, :production_daily_deal_host => "wickeddeals.com"
      deal = Factory :daily_deal, :publisher => publisher_1
      assert deal.publisher.publishing_group.blank?
      consumer = Factory :consumer, :referrer_code => "ABC123"
      
      begin
        loyalty_program_url(deal, consumer)
      rescue RuntimeError => e
        assert_equal "can't generate loyalty program url: this consumer belongs to a different publisher", e.message
      else
        assert false, "should have raised an exception"
      end
    end
    
    
  end

  context "map_image_url_for" do

    setup do
      @daily_deal = Factory(:daily_deal, :publisher => Factory(:publisher))
      @size = "640x250"
    end

    should "display map url with markers with multiple stores with defaults" do
      Factory(:store, :advertiser => @daily_deal.advertiser)
      @daily_deal.reload
      assert @daily_deal.advertiser.stores.size > 1, "should have multiple stores"
      store = @daily_deal.advertiser.store
      escaped_address = CGI.escape("#{store.address_line_1}, #{store.city}, #{store.state} #{store.zip}")
      assert_equal "http://maps.google.com/maps/api/staticmap?size=#{@size}&center=#{escaped_address}&markers=size:small|#{escaped_address}&key=ABQIAAAAzObGV3GscSCtMupcN2Jm-RSSjhI9lG3KGwm-Keiwru5ERTctHhTXe3LfYrff_rQT8DZgaQB6AthF0A&sensor=false", map_image_url_for(@daily_deal)
    end

    should "display map url with markers with multiple stores with multi_locaiton display set to true" do
      Factory(:store, :advertiser => @daily_deal.advertiser)
      @daily_deal.reload
      assert @daily_deal.advertiser.stores.size > 1, "should have multiple stores"
      escaped_addresses = @daily_deal.advertiser.stores.map {|s| CGI.escape("#{s.address_line_1}, #{s.city}, #{s.state} #{s.zip}") }
      assert_equal "http://maps.google.com/maps/api/staticmap?size=#{@size}&markers=size:small|#{escaped_addresses.join('|')}&sensor=false", map_image_url_for(@daily_deal, @size, true)
    end

    should "display map url for one store" do
      assert_equal 1, @daily_deal.advertiser.stores.size, "should only have one store"
      store = @daily_deal.advertiser.store
      escaped_address = CGI.escape("#{store.address_line_1}, #{store.city}, #{store.state} #{store.zip}")
      assert_equal "http://maps.google.com/maps/api/staticmap?size=#{@size}&center=#{escaped_address}&markers=size:small|#{escaped_address}&key=ABQIAAAAzObGV3GscSCtMupcN2Jm-RSSjhI9lG3KGwm-Keiwru5ERTctHhTXe3LfYrff_rQT8DZgaQB6AthF0A&sensor=false", map_image_url_for(@daily_deal)
    end

    should "display empty string with no store" do
      @daily_deal.advertiser.stores.destroy_all
      @daily_deal.reload
      assert @daily_deal.advertiser.stores.empty?, "should have no stores"
      assert_equal "", map_image_url_for(@daily_deal)
    end

  end

  context "#market_aware_daily_deal_url" do
    setup do
      @host = "publisher.host.com"
      @daily_deal = Factory(:daily_deal)
      @daily_deal.publisher.tap do |pub|
        pub.production_daily_deal_host = @host
        pub.save!
        assert_equal @host, pub.daily_deal_host
      end
    end

    should "include additional parameters in the url" do
      referral_code = "98234-234-234-23-43"
      assert_match /#{Regexp.escape "referral_code=#{referral_code}"}/, market_aware_daily_deal_url(@daily_deal, :referral_code => referral_code)
    end

    should "set the host to the publisher daily deal host" do
      assert_match /#{Regexp.escape @host}/, market_aware_daily_deal_url(@daily_deal, :something => "else")
    end
  end

  def hack_to_load_translations_association(daily_deal)
    daily_deal.reload
  end

  def params
    @params
  end
end

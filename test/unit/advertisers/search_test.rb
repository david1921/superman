require File.dirname(__FILE__) + "/../../test_helper"

class Advertisers::SearchTest < ActiveSupport::TestCase
  context ClassMethods do
    fast_context "#search" do
      setup do
        @publisher = Factory(:publisher)
        @advertiser_matching_postcode = Factory(:advertiser, :publisher => @publisher).tap do |adv|
          adv.stores.first.update_attributes!(:zip => 'E14 5HP', :country => Country::UK)
        end
        @advertiser_matching_name = Factory(:advertiser, :publisher => @publisher, :name => 'Funtimes Pizza Parlour')
        @advertiser_with_greek_name = Factory(:advertiser, :publisher => @publisher, :name => "Party Pizza").tap do |adv|
          adv.update_attributes!(:name => 'κόμμα πίτσα', :locale => :el)
        end
      end

      should "include partially matching zip/postcode (case-insensitive)" do
        assert_contains Advertiser.search(:zip => 'e14', :publisher => @publisher), @advertiser_matching_postcode
      end

      should "exclude mismatching zip/postcode" do
        assert_does_not_contain Advertiser.search(:zip => 'e15', :publisher => @publisher), @advertiser_matching_name
      end

      should "include partially matching name (case-insensitive)" do
        assert_contains Advertiser.search(:name => 'pizza', :publisher => @publisher), @advertiser_matching_name
      end

      should "exclude mismatching name" do
        assert_does_not_contain Advertiser.search(:zip => 'e15', :publisher => @publisher), @advertiser_matching_postcode
      end

      should "include with matching name and zip/postalcode" do
        advertiser_matching_name_and_zip = Factory(:advertiser, :publisher => @publisher, :name => "Paul's Pancakes").tap do |adv|
          adv.stores.first.update_attributes!(:zip => '97520')
        end
        assert_contains Advertiser.search(:name => 'Pancakes', :zip => '975', :publisher => @publisher), advertiser_matching_name_and_zip
      end

      should "include with anchored matching name" do
        assert_contains Advertiser.search(:name => '^F', :publisher => @publisher), @advertiser_matching_name
        assert_does_not_contain Advertiser.search(:name => '^pizza', :publisher => @publisher), @advertiser_matching_name
      end

      should "use the current locale" do
        I18n.with_locale(:en) do
          assert_contains Advertiser.search(:name => 'pizza', :publisher => @publisher), @advertiser_with_greek_name
        end

        I18n.with_locale(:el) do
          assert_contains Advertiser.search(:name => 'πίτσα', :publisher => @publisher), @advertiser_with_greek_name
        end
      end

      should "use locale passed in the options" do
        assert_contains Advertiser.search(:name => 'πίτσα', :locale => :el, :publisher => @publisher), @advertiser_with_greek_name
      end

    end

    context "old test moved from a publisher model test after refactoring" do
      should "return advertisers with counts" do
        publisher = publishers(:sdh_austin)

        create_txt_offer = lambda do |advertiser, options|
          advertiser.txt_offers.create!({
            :short_code => "898411",
            :keyword_prefix => advertiser.publisher.txt_keyword_prefix,
            :assign_keyword => "1",
          }.merge(options))
        end

        a1 = publisher.advertisers.create!(:name => "A1")
        a1.offers.create! :message => "A1 O1", :show_on => "Nov 01 2008", :expires_on => "Nov 30 2008"
        a1.offers.create! :message => "A1 O2", :show_on => "Nov 15 2008", :expires_on => "Nov 30 2008"
        a1.offers.create! :message => "A1 O3", :show_on => "Nov 01 2008", :expires_on => "Nov 15 2008"
        create_txt_offer.call a1, :message => "A1 T1", :expires_on => "Nov 15 2008"
        create_txt_offer.call a1, :message => "A1 T2", :appears_on => "Oct 01 2008", :expires_on => "Oct 31 2008"
        a1.users.create! :login => "A1U1", :password => "secret", :password_confirmation => "secret"

        a2 = publisher.advertisers.create!(:name => "A2")
        create_txt_offer.call a2, :message => "A2 T1", :appears_on => "Nov 01 2008"
        create_txt_offer.call a2, :message => "A2 T2", :appears_on => "Oct 01 2008", :expires_on => "Oct 31 2008"
        create_txt_offer.call a2, :message => "A2 T3"

        a3 = publisher.advertisers.create!(:name => "A3")
        a3.users.create! :login => "A3U1", :password => "secret", :password_confirmation => "secret"
        a3.users.create! :login => "A3U2", :password => "secret", :password_confirmation => "secret"

        Time.zone.stubs(:now).returns(DateTime.new(2008, 11, 15))
        advertisers = Advertiser.search(:publisher => publisher)
        assert_equal 5, advertisers.size

        advertiser = advertisers.detect { |a| a.id == a1.id }
        assert_not_nil advertiser, "Should contain entry for advertiser 1"
        assert_equal "A1", advertiser.name
        assert_equal 3, advertiser.offers_count
        assert_equal 3, advertiser.active_offers_count
        assert_equal 2, advertiser.txt_offers_count
        assert_equal 1, advertiser.active_txt_offers_count
        assert_equal 1, advertiser.users_count

        advertiser = advertisers.detect { |a| a.id == a2.id }
        assert_not_nil advertiser, "Should contain entry for advertiser 2"
        assert_equal "A2", advertiser.name
        assert_equal 0, advertiser.offers_count
        assert_equal 0, advertiser.active_offers_count
        assert_equal 3, advertiser.txt_offers_count
        assert_equal 2, advertiser.active_txt_offers_count
        assert_equal 0, advertiser.users_count

        advertiser = advertisers.detect { |a| a.id == a3.id }
        assert_not_nil advertiser, "Should contain entry for advertiser 3"
        assert_equal "A3", advertiser.name
        assert_equal 0, advertiser.offers_count
        assert_equal 0, advertiser.active_offers_count
        assert_equal 0, advertiser.txt_offers_count
        assert_equal 0, advertiser.active_txt_offers_count
        assert_equal 2, advertiser.users_count
      end
    end

  end
end
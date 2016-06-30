require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::MarketTest
module Publishers
  module PublisherModel
    class MarketTest < ActiveSupport::TestCase
      
      test "market name should allow nil" do
        publisher = Factory.build(:publisher, :market_name => nil)
        publisher.save
        assert publisher.errors.empty?, "Should have no errors with characters and spaces"
      end

      test "market name should allow blank" do
        publisher = Factory.build(:publisher, :market_name => "")
        publisher.save
        assert publisher.errors.empty?, "Should have no errors with characters and spaces"
      end

      test "market name can contain characters and spaces" do
        publisher = Factory.build(:publisher, :market_name => "Phoenix West")
        publisher.save
        assert publisher.errors.empty?, "Should have no errors with characters and spaces"
      end

      test "market name can contain dots" do
        publisher = Factory.build(:publisher, :market_name => "Ft. Worth")
        publisher.save
        assert publisher.errors.empty?, "Should have no errors with dots"
      end
      
      test "market name can contain hyphens" do
        publisher = Factory.build(:publisher, :market_name => "Dallas-Fort Worth")
        assert publisher.valid?, "Should have no errors with hyphens"
      end

      test "market name should not contain anything other than characters, dots or spaces" do
        publisher = Factory.build(:publisher, :market_name => "Ft. Worth#")
        publisher.save
        assert publisher.errors.on(:market_name), "Should have an error on active_txt_coupon_limit"
      end

      test "market name or city should return city when market name blank" do
        publisher = Factory(:publisher,
                            :market_name => nil,
                            :city => "Phoenix",
                            :state => "AZ",
                            :address_line_1 => "123 A Street",
                            :zip => "12345")
        assert_equal "Phoenix", publisher.market_name_or_city
      end

      test "market name or city should return market name when market name not blank" do
        publisher = Factory(:publisher,
                            :market_name => "Phoenix West",
                            :city => "Phoenix",
                            :state => "AZ",
                            :address_line_1 => "123 A Street",
                            :zip => "12345")
        assert_equal "Phoenix West", publisher.market_name_or_city
      end

      test "market base uri should be city if market name nil" do
        publisher = Factory(:publisher,
                            :market_name => nil,
                            :city => "Phoenix",
                            :state => "AZ",
                            :address_line_1 => "123 A Street",
                            :zip => "12345")
        assert_equal "/phoenix", publisher.market_base_uri
      end

      test "market base uri should be market name if market name not nil" do
        publisher = Factory(:publisher,
                            :market_name => "Phoenix West",
                            :city => "Phoenix",
                            :state => "AZ",
                            :address_line_1 => "123 A Street",
                            :zip => "12345")
        assert_equal "/phoenix-west", publisher.market_base_uri
      end

      test "market base uri should remove dots" do
        publisher = Factory.build(:publisher,
                                  :market_name => "Ft. Worth.")
        publisher.save
        assert publisher.errors.empty?, "Should have no errors with dots"
        assert_equal "/ft-worth", publisher.market_base_uri
      end

      context "finding markets by state" do
        setup do
          # Three NY markets, one that doesn't have any deals
          @publisher = Factory(:publisher)
          @big_apple = Factory(:market, :publisher_id => @publisher.id, :name => "The Big Apple")
          @big_apple_zip_1 = Factory(:market_zip_code, :market_id => @big_apple.id, :zip_code => "10001", :state_code => "NY")
          @ny_deal = Factory(:side_daily_deal, :publisher_id => @publisher.id)
          @ny_deal.markets << @big_apple

          # Give the Rochester deal more than one market zip code mapping so we know there aren't issues with joining returning multiple rows
          @rochester = Factory(:market, :publisher_id => @publisher.id, :name => "Rochester")
          @rochester_zip_1 = Factory(:market_zip_code, :market_id => @rochester.id, :zip_code => "82193", :state_code => "NY")
          @rochester_zip_2 = Factory(:market_zip_code, :market_id => @rochester.id, :zip_code => "82194", :state_code => "NY")
          @rochester_deal = Factory(:side_daily_deal, :publisher_id => @publisher.id)
          @rochester_deal.markets << @rochester

          # Catskills has no deal
          @catskills = Factory(:market, :publisher_id => @publisher.id, :name => "Catskills")
          @catskills_zip_1 = Factory(:market_zip_code, :market_id => @catskills.id, :zip_code => "98765", :state_code => "NY")

          # A market in another state
          @boston = Factory(:market, :publisher_id => @publisher.id, :name => "Boston")
          @boston_zip_1 = Factory(:market_zip_code, :market_id => @boston.id, :zip_code => "02810", :state_code => "MA")
          @boston_deal = Factory(:side_daily_deal, :publisher_id => @publisher.id)
          @boston_deal.markets << @boston
        end

        should "return only markets with deals in the provided state" do
          markets = @publisher.markets_with_deals_for_state("NY")
          market_names = markets.map { |m| m.name }
          assert_equal 2, markets.size
          assert market_names.include?("The Big Apple")
          assert market_names.include?("Rochester")
          assert !market_names.include?("Catskills")
        end

        should "return an empty collection if no markets are in the provided state" do
          markets =  @publisher.markets_with_deals_for_state("CA")
          assert_equal 0, markets.size
        end

        should "not return markets from another publisher" do
          another_publisher = Factory(:publisher)
          another_big_apple = Factory(:market, :publisher_id => another_publisher.id, :name => "Another Big Apple")
          another_big_apple_zip_1 = Factory(:market_zip_code, :market_id => another_big_apple.id, :zip_code => "10001", :state_code => "NY")
          another_big_apple_deal = Factory(:side_daily_deal, :publisher_id => another_publisher)
          another_big_apple_deal.markets << another_big_apple
          markets = @publisher.markets_with_deals_for_state("NY")
          assert_equal 2, markets.size
        end
      end

    end
  end
end

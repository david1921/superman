require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::YelpTest < ActiveSupport::TestCase
  include YelpTestHelper

  context "given a yelp_api_business_id" do
    setup do
      @publisher = Factory(:publisher_with_yelp_credentials)
      @daily_deal = Factory.build(:daily_deal, :publisher => @publisher)
    end

    context "the publisher does not have yelp credentials" do
      setup do
        @publisher.update_attributes(:yelp_consumer_key => nil)
      end

      should "have validation errors" do
        @daily_deal.update_attributes(:yelp_api_business_id => "a-test-business")
        assert @daily_deal.errors.full_messages.include?("Publisher does not have Yelp credentials set")
      end
    end

    context "the business is already cached" do
      setup do
        @existing_yelp_business = Factory(:yelp_business, :yelp_id => "a-restaurant")
      end

      should "associate the existing business to the deal" do
        @daily_deal.update_attributes(:yelp_api_business_id => "a-restaurant")
        @daily_deal.reload

        assert_equal @existing_yelp_business.id, @daily_deal.yelp_business.id
      end

      should "not create new cache records" do
        assert_no_yelp_records_created_or_destroyed do
          @daily_deal.update_attributes(:yelp_api_business_id => "a-restaurant")
        end
      end

      should "not make any yelp API calls" do
        expect_no_yelp_api_calls
        @daily_deal.update_attributes(:yelp_api_business_id => "a-restaurant")
      end
    end

    context "the business is not already cached" do
      context "a business is found for the given id" do
        should "create yelp cache records associated with the deal" do
          assert_difference "YelpBusiness.count", 1 do
            assert_difference "YelpReview.count", 1 do
              @daily_deal.update_attributes(:yelp_api_business_id => "a-test-business")
              @daily_deal.reload

              yelp_business = @daily_deal.yelp_business
              assert_equal "Test Business", yelp_business.name

              yelp_reviews = yelp_business.yelp_reviews
              assert_equal 1, yelp_reviews.count
              assert_equal "Hen A.", yelp_reviews[0].user_name
            end
          end
        end
      end

      context "no business is found with the given id" do
        should "have validation errors" do
          @daily_deal.update_attributes(:yelp_api_business_id => "not-a-business")
          assert_equal "not-a-business", @daily_deal.yelp_api_business_id
          assert @daily_deal.errors.full_messages.include?("No Yelp business found with ID='not-a-business'")
        end

        should "not create any cache records" do
          assert_no_yelp_records_created_or_destroyed do
            @daily_deal.update_attributes(:yelp_api_business_id => "not-a-business")
          end
        end
      end
    end

  end

  context "given a yelp_api_business_id set to nil" do
    setup do
      @daily_deal = Factory.build(:daily_deal)
    end

    context "given a yelp_business is set" do
      setup do
        @yelp_business = Factory(:yelp_business, :yelp_id => "a-restaurant")
        @daily_deal.update_attributes(:yelp_business => @yelp_business)
      end

      should "not change the associated yelp business" do
        @daily_deal.update_attributes(:yelp_api_business_id => nil)
        @daily_deal.reload

        assert_equal @daily_deal.yelp_business.id, @yelp_business.id
      end

      should "not create any cache records" do
        assert_no_yelp_records_created_or_destroyed do
          @daily_deal.update_attributes(:yelp_api_business_id => nil)
        end
      end

      should "not make any yelp API calls" do
        expect_no_yelp_api_calls
        @daily_deal.update_attributes(:yelp_api_business_id => nil)
      end
    end

    context "given a yelp_business is not set" do
      should "not create any cache records" do
        assert_no_yelp_records_created_or_destroyed do
          @daily_deal.update_attributes(:yelp_api_business_id => nil)
        end
      end

      should "not make any yelp API calls" do
        expect_no_yelp_api_calls
        @daily_deal.update_attributes(:yelp_api_business_id => nil)
      end
    end
  end

  context "given a yelp_api_business_id set to an empty string" do
    setup do
      @daily_deal = Factory.build(:daily_deal)
    end

    context "given a yelp_business is set" do
      should "disassociated yelp business" do
        @daily_deal.update_attributes(:yelp_api_business_id => "")
        @daily_deal.reload

        assert_equal nil, @daily_deal.yelp_business
      end

      should "not create or destroy any yelp cache records" do
        assert_no_yelp_records_created_or_destroyed do
          @daily_deal.update_attributes(:yelp_api_business_id => "")
        end
      end

      should "not make any yelp API calls" do
        expect_no_yelp_api_calls
        @daily_deal.update_attributes(:yelp_api_business_id => "")
      end
    end

    context "given a yelp_business is not set" do
      should "not create any cache records" do
        assert_no_yelp_records_created_or_destroyed do
          @daily_deal.update_attributes(:yelp_api_business_id => "")
        end
      end

      should "not make any yelp API calls" do
        expect_no_yelp_api_calls
        @daily_deal.update_attributes(:yelp_api_business_id => "")
      end
    end
  end
end

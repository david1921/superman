require File.dirname(__FILE__) + "/../test_helper"

class YelpBusinessTest < ActiveSupport::TestCase
  include YelpTestHelper

  should have_many :yelp_reviews

  should validate_presence_of :yelp_id
  should validate_presence_of :url
  should validate_presence_of :rating_image_url
  should validate_presence_of :average_rating
  should validate_presence_of :review_count

  context "new_via_api" do

    setup do
      @credentials = nil # mocked out
    end

    context "given a valid yelp id" do
      setup do
        @business_id = "a-test-business"
      end

      should "populate attributes" do
        @business = YelpBusiness.new_via_api(@credentials, @business_id)

        assert_equal "Test Business", @business.name
        assert_equal "http://www.yelp.com/biz/a-test-business", @business.url
        assert_equal 2.0, @business.average_rating
        assert_equal "http://example.com/rating_image.png", @business.rating_image_url
        assert_equal 220, @business.review_count

        assert_equal 1, @business.yelp_reviews.size

        review = @business.yelp_reviews[0]
        assert_equal 5, review.rating
        assert_equal "A great business!", review.excerpt
        assert_equal "Hen A.", review.user_name
        assert_equal "http://example.com/user_image.jpg", review.user_image_url
        assert_equal Time.at(1317918655), review.reviewed_at
      end

      should "not persist any values" do
        assert_no_difference "YelpBusiness.count" do
          assert_no_difference "YelpReview.count" do
            @business = YelpBusiness.new_via_api(@credentials, @business_id)
          end
        end
      end
    end

    context "given an invalid yelp id" do
      setup do
        business_id = "not-a-real-id-123"
        @business = YelpBusiness.new_via_api(@credentials, business_id)
      end

      should "return nil" do
        assert_equal nil, @business
      end
    end

  end

  context "find_or_initialize_by_business_id_via_api" do
    setup do
      @credentials = nil # mocked out
    end

    context "the business is already cached" do
      setup do
        @existing_yelp_business = Factory(:yelp_business, :yelp_id => "a-restaurant")
      end

      should "return the exisdting business" do
        found_business = YelpBusiness.find_or_initialize_by_business_id_via_api(@credentials, "a-restaurant")
        assert_equal @existing_yelp_business.id, found_business.id
      end

      should "not create new cache records" do
        assert_no_yelp_records_created_or_destroyed do
          YelpBusiness.find_or_initialize_by_business_id_via_api(@credentials, "a-restaurant")
        end
      end

      should "not make any yelp API calls" do
        expect_no_yelp_api_calls
        YelpBusiness.find_or_initialize_by_business_id_via_api(@credentials, "a-restaurant")
      end
    end

    context "the business is not already cached" do
      context "a business is found for the given id" do
        should "initialize yelp cache records associated with the deal" do
          assert_difference "YelpBusiness.count", 0 do
            assert_difference "YelpReview.count", 0 do
              yelp_business = YelpBusiness.find_or_initialize_by_business_id_via_api(@credentials, "a-test-business")
              assert_equal "Test Business", yelp_business.name

              yelp_reviews = yelp_business.yelp_reviews
              assert_equal 1, yelp_reviews.size
              assert_equal "Hen A.", yelp_reviews[0].user_name
            end
          end
        end
      end

      context "no business is found with the given id" do
        should "return nil" do
          assert_equal nil, YelpBusiness.find_or_initialize_by_business_id_via_api(@credentials, "no-a-business")
        end

        should "not create any cache records" do
          assert_no_yelp_records_created_or_destroyed do
            YelpBusiness.find_or_initialize_by_business_id_via_api(@credentials, "no-a-business")
          end
        end
      end
    end

  end

end

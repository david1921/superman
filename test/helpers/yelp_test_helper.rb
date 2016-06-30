module YelpTestHelper
  private

  def assert_no_yelp_records_created_or_destroyed
    assert_no_difference "YelpBusiness.count" do
      assert_no_difference "YelpReview.count" do
        yield
      end
    end
  end

  def expect_no_yelp_api_calls
    Yelp::Client.expects(:new).never
    Yelp::Client.any_instance.expects(:find_business).never
  end
end

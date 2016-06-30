require File.dirname(__FILE__) + "/../../controllers_helper"

# hydra class DailyDeals::FilteringTest
module DailyDeals
  class FilteringTest < Test::Unit::TestCase

    context "current_radius_filter_zip_code" do
      setup do
        @controller = stub
        @controller.extend(DailyDeals::Filtering)
        @controller.stubs(:cookies).returns({})
        @controller.stubs(:current_user).returns(nil)
      end

      context "given both cookies[:zip_code] and current_user is set" do
        setup do
          @controller.stubs(:cookies).returns({"zip_code" => "90211"})
          @controller.stubs(:current_user).returns(stub.stubs(:zip).returns("98686"))
        end

        should "return the cookie's value" do
          assert_equal "90211", @controller.current_radius_filter_zip_code
        end
      end

      context "given cookies[:zip_code] is set" do
        setup do
          @controller.stubs(:cookies).returns({"zip_code" => "90211"})
        end

        should "return the cookie's value" do
          assert_equal "90211", @controller.current_radius_filter_zip_code
        end
      end

      context "given current_user is set" do
        setup do
          user = stub
          user.stubs(:zip_code).returns("98686")
          @controller.stubs(:current_user).returns(user)
        end

        should "return the user's zip" do
          assert_equal "98686", @controller.current_radius_filter_zip_code
        end
      end

      context "given neither is set" do
        should "return nil" do
          assert_equal nil, @controller.current_radius_filter_zip_code
        end
      end
    end

  end
end

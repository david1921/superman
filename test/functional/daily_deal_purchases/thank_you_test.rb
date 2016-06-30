require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::ThankYouTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  context "GET to thank_you, with a purchase session token" do

    should "not show refer a friend bullet if not enabled" do
      publisher = Factory(:publisher, :enable_daily_deal_referral => false, :daily_deal_referral_message => "Refer a friend");
      advertiser = Factory(:advertiser, :publisher => publisher)
      daily_deal = Factory(:daily_deal, :advertiser => advertiser)
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
      stub_flash_analytics_tag_with(daily_deal_purchase)

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :success
      assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)

      assert @controller.analytics_tag.sale?
      assert_equal 15.00, @controller.analytics_tag.data.value

      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "View your orders"
      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "Back to the Deal"
      assert_no_tag :tag => "a", :parent => { :tag => "li"}, :content => "Refer a friend"
    end

    should "not show refer a friend bullet if enabled and referral message head is nil" do
      publisher = Factory(:publisher, :enable_daily_deal_referral => true, :daily_deal_referral_message => nil);
      advertiser = Factory(:advertiser, :publisher => publisher)
      daily_deal = Factory(:daily_deal, :advertiser => advertiser)
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
      stub_flash_analytics_tag_with(daily_deal_purchase)

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :success
      assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)

      assert @controller.analytics_tag.sale?
      assert_equal 15.00, @controller.analytics_tag.data.value

      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "View your orders"
      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "Back to the Deal"
      assert_no_tag :tag => "a", :parent => { :tag => "li"}, :content => "Refer a friend"
    end

    should "not show refer a friend bullet if enabled and referral message head is empty" do
      publisher = Factory(:publisher, :enable_daily_deal_referral => true, :daily_deal_referral_message => "");
      advertiser = Factory(:advertiser, :publisher => publisher)
      daily_deal = Factory(:daily_deal, :advertiser => advertiser)
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
      stub_flash_analytics_tag_with(daily_deal_purchase)

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :success
      assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)

      assert @controller.analytics_tag.sale?
      assert_equal 15.00, @controller.analytics_tag.data.value

      assert_tag :tag => "a", :parent => { :tag => "li" }, :content => "View your orders"
      assert_tag :tag => "a", :parent => { :tag => "li" }, :content => "Back to the Deal"
      assert_no_tag :tag => "a", :parent => { :tag => "li" }, :content => "Refer a friend", :attributes => { :href => "/publishers/#{ publisher.id }/consumers/refer_a_friend" }
    end

    should "show refer a friend bullet if enabled and has referral message head" do
      publisher = Factory(:publisher, :enable_daily_deal_referral => true, :daily_deal_referral_message => "Refer a friend");
      advertiser = Factory(:advertiser, :publisher => publisher)
      daily_deal = Factory(:daily_deal, :advertiser => advertiser)
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
      stub_flash_analytics_tag_with(daily_deal_purchase)

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :success
      assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)

      assert @controller.analytics_tag.sale?
      assert_equal 15.00, @controller.analytics_tag.data.value

      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "View your orders"
      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "Back to the Deal"
      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "Refer a friend"
    end

    should "render correctly with payment method of optimal" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase)
      daily_deal_purchase.publisher.update_attribute(:payment_method, 'optimal')

      stub_flash_analytics_tag_with(daily_deal_purchase)

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :success
      assert_layout   :optimal
      assert_template :optimal_thank_you
      assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)

      assert @controller.analytics_tag.sale?
      assert_equal 15.00, @controller.analytics_tag.data.value
      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "View your orders"
      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "Back to the Deal"
      assert_no_tag :tag => "a", :parent => { :tag => "li"}, :content => "Refer a friend"
    end

    should "only record one sale if reloaded" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase)

      @controller.analytics_tag.expects(:sale!)
      stub_flash_analytics_tag_with(daily_deal_purchase)

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :success
      assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)

      @controller.stubs(:flash).returns({})

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :success
      assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)
    end

    should "render correctly" do
      daily_deal_purchase = Factory(:captured_daily_deal_purchase)
      stub_flash_analytics_tag_with(daily_deal_purchase)

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :success
      assert_equal daily_deal_purchase, assigns(:daily_deal_purchase)

      assert @controller.analytics_tag.sale?
      assert_equal 15.00, @controller.analytics_tag.data.value
      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "View your orders"
      assert_tag :tag => "a", :parent => { :tag => "li"}, :content => "Back to the Deal"
      assert_no_tag :tag => "a", :parent => { :tag => "li"}, :content => "Refer a friend"
    end

  end

  test "execute_free sets flash[:analytics_tag]" do
    daily_deal_purchase = Factory(:captured_daily_deal_purchase)

    DailyDealPurchase.expects(:find_by_uuid!).returns(daily_deal_purchase)
    daily_deal_purchase.expects(:execute_without_payment!).returns(true)

    flash_analytics_tag = {
      :value    => daily_deal_purchase.amount,
      :quantity => daily_deal_purchase.quantity,
      :item_id  => daily_deal_purchase.daily_deal_id,
      :sale_id  => daily_deal_purchase.id
    }

    post :execute_free, :id => daily_deal_purchase.to_param
    assert_response :redirect
    assert_equal flash_analytics_tag, flash[:analytics_tag]
  end

  context "authentication, with and without a purchase session" do

    context 'GET to :thank_you when signed in as a consumer' do
      setup do
        daily_deal_purchase = Factory :pending_daily_deal_purchase
        login_as(daily_deal_purchase.consumer)
        get :thank_you, :id => daily_deal_purchase.to_param
      end

      should 'succeed' do
        assert_response :success
      end
    end

    context 'GET to :thank_you with a purchase session token' do
      setup do
        daily_deal_purchase = Factory :pending_daily_deal_purchase
        set_purchase_session daily_deal_purchase
        get :thank_you, :id => daily_deal_purchase.to_param
      end

      should 'succeed' do
        assert_response :success
      end
    end

    context 'GET to :thank_you, not signed in and no purchase session' do
      setup do
        @daily_deal_purchase = Factory :pending_daily_deal_purchase
        get :thank_you, :id => @daily_deal_purchase.to_param
      end

      should 'redirect to login' do
        assert_redirected_to new_publisher_daily_deal_session_path(@daily_deal_purchase.daily_deal.publisher)
      end
    end

  end

  context "TRAVELSAVERS purchase, with a purchase session" do

    should "render the TRAVELSAVERS thank you page" do
      booking = Factory(:successful_travelsavers_booking)
      daily_deal_purchase = booking.daily_deal_purchase

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :ok
      assert_template 'thank_you/travelsavers'

      assert_select "#travelsavers_thank_you" do
        assert_select "#product_name", booking.product_name
        assert_select "#provider_name", booking.provider_name
        assert_select "#product_date", booking.formatted_product_date
        assert_select "#subproduct_name", booking.subproduct_name
        assert_select "#total_charges", booking.total_charges
        assert_select "#confirmation_number", booking.confirmation_number

        assert_select "#passengers" do
          booking.passengers.each_with_index do |passenger, i|
            assert_select "#passenger_#{i}.passenger" do
              assert_select ".passenger_name", passenger.name
              assert_select ".passenger_address1", passenger.address1
              assert_select ".passenger_address2", 0
              assert_select ".passenger_locality", passenger.locality
              assert_select ".passenger_region", passenger.region
              assert_select ".passenger_postal_code", passenger.postal_code
              assert_select ".passenger_country", passenger.country_code
              assert_not_nil passenger.birth_date
              assert_select ".passenger_birth_date", "Date Of Birth: #{passenger.birth_date.strftime("%m/%d/%Y")}"
            end
          end
        end

        assert_select "#next_steps", 1
        assert_similar_html booking.next_steps.html, Nokogiri::HTML(@response.body).css("#next_steps").inner_html, "Next Steps html did not match"
      end
    end

    should "render the TRAVELSAVERS thank you page when there are no next steps present" do
      booking = Factory(:successful_travelsavers_booking_without_next_steps)
      daily_deal_purchase = booking.daily_deal_purchase
      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_response :ok
      assert_template 'thank_you/travelsavers'

      assert_select "#travelsavers_thank_you" do
        assert_select "#product_name", booking.product_name
        assert_select "#subproduct_name", booking.subproduct_name
        assert_select "#total_charges", booking.total_charges
        assert_select "#confirmation_number", booking.confirmation_number

        assert_select "#passengers" do
          booking.passengers.each_with_index do |passenger, i|
            assert_select "#passenger_#{i}.passenger" do
              assert_select ".passenger_name", passenger.name
              assert_select ".passenger_address1", passenger.address1
              assert_select ".passenger_address2", 0
              assert_select ".passenger_locality", passenger.locality
              assert_select ".passenger_region", passenger.region
              assert_select ".passenger_postal_code", passenger.postal_code
              assert_select ".passenger_country", passenger.country_code
              assert_not_nil passenger.birth_date
              assert_select ".passenger_birth_date", "Date Of Birth: #{passenger.birth_date.strftime("%m/%d/%Y")}"
            end
          end
        end

        assert_select "#next_steps"
        assert Nokogiri::HTML(@response.body).css("#next_steps").inner_html.blank?
      end
    end

  end

  test "google conversion tags, with a purchase session" do
    publishing_group = Factory(:publishing_group, :label => 'freedom')

    %w{ themonitor }.each do |label|
      publisher = Factory(:publisher, :label => label, :publishing_group => publishing_group)
      daily_deal = Factory(:daily_deal, :publisher => publisher )
      daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)

      set_purchase_session daily_deal_purchase
      get :thank_you, :id => daily_deal_purchase.to_param
      assert_select 'script[src=http://www.googleadservices.com/pagead/conversion.js]'
    end
  end
end

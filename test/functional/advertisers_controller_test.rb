require File.dirname(__FILE__) + "/../test_helper"

class AdvertisersControllerTest < ActionController::TestCase
  assert_no_angle_brackets :except => [ :test_CNHI_using_withtheme_for_public_index, :test_CNHI_using_withtheme_for_public_index_with_map ]

  setup :setup_advertiser
  
  def setup_advertiser
    @publisher = publishers(:sdh_austin)
  end

  def test_create
    check_result = lambda do |role|
      advertiser = assigns['advertiser']
      assert_redirected_to edit_publisher_advertiser_path(@publisher, advertiser), "Should be redirected to advertiser edit as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"


      assert_not_nil advertiser, "Assignment of @advertiser as #{role}"
      assert_nil advertiser.store, "Advertiser should not have store as #{role}"
      assert advertiser.errors.empty?, "Advertiser should not have errors but has #{advertiser.errors.full_messages} as #{role}"
      assert flash[:notice].present?, "Should have flash as #{role}"
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      post :create, 'publisher_id' => @publisher.to_param, 'advertiser' => {
            :stores_attributes => {
              "0" => { 
                "city"=>"", "zip"=>"", "address_line_1"=>"", "phone_number"=>"", "address_line_2"=>"", "state"=>""
              }
            }
      }
    end
  end

  def test_create_with_paychex_publisher
    publisher = Factory(:publisher_using_paychex)
    assert_equal 0, publisher.advertisers.size, "publisher should have no advertisers yet"
    login_as Factory(:admin)

    post :create, :publisher_id => publisher.to_param, :advertiser => {
        :stores_attributes => {
          "0" => { 
            "city"=>"Portland", "zip"=>"97206", "address_line_1"=>"123 Main St", "phone_number"=>"", "address_line_2"=>"", "state"=>"OR"
          }
        }      
    }
    assert_equal 1, publisher.reload.advertisers.size, "publisher should now have 1 advertiser"
  end

  def test_create_just_phone_number_for_paychex_publisher
    publisher = Factory(:publisher_using_paychex)
    assert_equal 0, publisher.advertisers.size, "publisher should have no advertisers yet"
    login_as Factory(:admin)

    post :create, :publisher_id => publisher.to_param, :advertiser => {
        :stores_attributes => {
          "0" => { 
            "city"=>"", "zip"=>"", "address_line_1"=>"", "phone_number"=>"555-123-4567", "address_line_2"=>"", "state"=>""
          }
        }      
    }
    assert_equal 0, publisher.reload.advertisers.size, "a new advertiser should not be created with just a phone number"
  end  

  def test_create_blank_store
    check_result = lambda do |role|
      advertiser = assigns['advertiser']
      assert_redirected_to edit_publisher_advertiser_path(@publisher, advertiser), "Should be redirected to advertiser edit as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"

      assert_not_nil advertiser, "Assignment of @advertiser as #{role}"
      assert advertiser.errors.empty?, "Advertiser should not have errors but has #{advertiser.errors.full_messages} as #{role}"
      assert flash[:notice].present?, "Should have flash as #{role}"
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      post :create, 'publisher_id' => @publisher.to_param, 'advertiser' => {}
    end
  end

  def test_invalid_create
    check_result = lambda do |role|
      assert_response :success, "Should have success response as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"

      advertiser = assigns['advertiser']
      assert_not_nil advertiser, "Assignment of @advertiser as #{role}"
      assert advertiser.new_record?, "Advertiser should be a new record as #{role}"
      assert advertiser.errors.present?, "Advertiser have errors as #{role}"
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      post :create, 'publisher_id' => @publisher.to_param, 'advertiser' => { 
                      'coupon_clipping_modes' => [ "call" ], 
                      :logo => ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
      }
    end
  end

  def test_clear_logo
    advertiser = @publisher.advertisers.first
    advertiser.logo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    advertiser.save!
    
    @request.session[:user_id] = users(:aaron)
    xhr :post, :clear_logo, :id => advertiser.to_param
    assert_response :success

    # Get latest attachment state from DB
    advertiser = Advertiser.find(advertiser.id)
    assert !advertiser.logo.file?, "Should remove logo image file"
  end
  
  def test_delete_with_just_one_advertiser
    publisher   = Factory(:publisher, :self_serve => true)
    advertiser  = Factory(:advertiser, :publisher => publisher )
    user        = Factory(:user, :company => publisher)

    login_as(user)
    post :delete, :publisher_id => publisher.to_param, :id => [advertiser.id]
    
    assert_redirected_to publisher_advertisers_path(publisher)
    assert advertiser.reload.deleted?, "should have marked advertiser as deleted"

  end
  
  def test_delete_with_multiple_advertisers
    
    publisher                 = Factory(:publisher, :self_serve => true)
    do_not_delete_advertiser  = Factory(:advertiser, :publisher => publisher)
    advertiser_1              = Factory(:advertiser, :publisher => publisher)
    advertiser_2              = Factory(:advertiser, :publisher => publisher)
    user                      = Factory(:user, :company => publisher)
    
    login_as(user)
    post :delete, :publisher_id => publisher.to_param, :id => [advertiser_1, advertiser_2].map(&:id)
    
    assert_redirected_to publisher_advertisers_path(publisher)
    assert advertiser_1.reload.deleted?, "should have marked advertiser_1 as deleted"
    assert advertiser_2.reload.deleted?, "should have marked advertiser_2 as deleted"
    assert !do_not_delete_advertiser.reload.deleted?, "should not delete do_not_delete_advertiser"
    
  end

  def test_delete_other_publishers_advertiser
    publisher_user = User.all.detect { |user| @publisher == user.company }
    assert publisher_user, "Publisher should have a user"
    @request.session[:user_id] = publisher_user.id
    
    other_publisher = Publisher.all.find { |publisher| @publisher != publisher && 0 < publisher.advertisers.count }
    assert other_publisher, "Should have another publisher with advertisers"
    other_publisher_advertisers = other_publisher.advertisers.sort
    
    assert_raises ActiveRecord::RecordNotFound do
      post :delete, 'publisher_id' => other_publisher.to_param, 'id' => other_publisher.advertisers.map(&:id)
    end
    assert_equal other_publisher.advertisers(true).sort, other_publisher_advertisers, "Other publisher's advertisers should not be deleted"
  end
  
  def test_create_without_listing_with_publisher_listing_flag
    @publisher.advertiser_has_listing = true

    check_result = lambda do |role|
      assert_response :success, "Should have success response as #{role}"
      assert_template :edit, "Should use edit template as #{role}"

      advertiser = assigns['advertiser']
      assert_not_nil advertiser, "Assignment of @advertiser as #{role}"
      assert advertiser.new_record?, "Advertiser should be a new record as #{role}"
      assert advertiser.errors.on(:listing), "Advertiser should have errors on listing attr as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      post :create, 'publisher_id' => @publisher.to_param, 'advertiser' => {}
    end
  end

  def test_create_with_listing_without_publisher_listing_flag
    listing = "12345"
    check_result = lambda do |role|
      advertiser = assigns['advertiser']
      assert_redirected_to edit_publisher_advertiser_path(@publisher, advertiser), "Should be redirected to advertiser edit as #{role}"
      assert_equal "Created Some new advertiser", flash[:notice]
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      Advertiser.find_by_listing(listing).try(:destroy)
      post :create, 'publisher_id' => @publisher.to_param, 'advertiser' => { :listing => listing, :name => "Some new advertiser" }
    end
  end
  
  def test_create_with_non_unique_listing_with_publisher_listing_flag
    listing = "1234"
    @publisher.update_attributes! :advertiser_has_listing => true
    
    check_result = lambda do |role|
      assert_response :success, "Should have success response as #{role}"
      assert_template :edit, "Should use edit template as #{role}"

      advertiser = assigns['advertiser']
      assert_not_nil advertiser, "Assignment of @advertiser as #{role}"
      assert advertiser.new_record?, "Advertiser should be a new record as #{role}"
      assert advertiser.errors.on(:listing), "Advertiser should have errors on listing attr as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      Advertiser.find_all_by_listing(listing).each(&:destroy)
      @publisher.advertisers.create! :listing => listing
      post :create, 'publisher_id' => @publisher.to_param, 'advertiser' => { :listing => listing }
    end
  end
  
  def test_create_with_unique_listing_with_publisher_listing_flag
    listing = "1234"
    @publisher.update_attributes! :advertiser_has_listing => true
    
    check_result = lambda do |role|
      advertiser = assigns['advertiser']
      assert_redirected_to edit_publisher_advertiser_path(@publisher, advertiser), "Should be redirected to advertiser edit as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"

      assert_not_nil advertiser, "Assignment of @advertiser as #{role}"
      assert advertiser.errors.empty?, "Advertiser should not have errors but has #{advertiser.errors.full_messages} as #{role}"
      assert_equal listing, advertiser.listing, "Advertiser listing as #{role}"
      assert flash[:notice].present?, "Should have flash as #{role}"
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      Advertiser.find_all_by_listing(listing).each(&:destroy)
      post :create, 'publisher_id' => @publisher.to_param, 'advertiser' => { :listing => listing }
    end
  end
  
  def test_subscribe_for_non_paid_advertiser
    @publisher.update_attributes! :self_serve => true
    advertiser = advertisers(:changos)
    assert_equal @publisher, advertiser.publisher, "Advertiser fixture should belong to @publisher"
    assert !advertiser.paid, "Advertiser fixture should not be paid"
    
    check_result = lambda do |role|
      assert_response :success, role
      assert_equal advertiser, assigns(:advertiser), "Assignment of @advertiser as #{role}"
      assert_select "p.notice", /cannot subscribe/i, 1
    end
    
    with_login_managing_advertiser_required(advertiser, check_result) do
      get :subscribe, :id => advertiser.to_param
    end
  end

  def test_subscribe_for_paid_advertiser_not_active
    @publisher.update_attributes!( :self_serve => true, :enable_paypal_buy_now => true )
    subscription_rate_schedule = subscription_rate_schedules(:sdh_austin_rates)
    assert subscription_rate_schedule.subscription_rates.count > 0, "Subscription rate schedule fixture should have a subscription rate"
    assert @publisher.enable_paypal_buy_now?, "publisher should be enable for paypal"

    advertiser = @publisher.advertisers.create!(
      :name => "Advertiser",
      :paid => true,
      :subscription_rate_schedule => subscription_rate_schedule
    )
    advertiser.users.create!(:login => "paid@user.com", :password => "changeme", :password_confirmation => "changeme")

    check_result = lambda do |role|
      assert_response :success, role
      assert_equal advertiser, assigns(:advertiser), "Assignment of @advertiser as #{role}"
      subscription_rate_schedule.subscription_rates.each do |subscription_rate|
        assert_select "div.subscription_rate#subscription_rate_#{subscription_rate.id}", 1 do
          assert_select "form[action='#{PaypalConfiguration.sandbox.ipn_url}'][method=post]", 1 do
            assert_select "input[type=hidden][name*=cmd][value=_xclick-subscriptions]", 1
            assert_select "input[type=hidden][name=a3][value=#{subscription_rate.regular_price}]", 1
            assert_select "input[type=hidden][name=p3][value=#{subscription_rate.regular_period}]", 1
            assert_select "input[type=hidden][name=t3][value=#{subscription_rate.regular_time_unit[0, 1].upcase}]", 1
            assert_select "input[type=hidden][name=sra][value=1]", 1
            assert_select "input[type=hidden][name=src][value=#{subscription_rate.recurs ? 1 : 0}]", 1
            assert_select "input[type=hidden][name=srt][value=#{subscription_rate.recurs ? subscription_rate.recurring_count : 0}]", 1
            assert_select "input[type=image][src*=paypal.com]"
          end
        end
      end
    end

    with_login_managing_advertiser_required(advertiser, check_result) do
      get :subscribe, :id => advertiser.to_param
    end
  end
  
  test "CNHI using withtheme for public_index" do
    @publishing_group = Factory(:publishing_group, :label => 'cnhi')
    @publisher        = Factory(:publisher, :label => "cnhi-lakeoconeebreeze", :publishing_group => @publishing_group, :theme => "withtheme", :production_host => "localhost")
    get :public_index, :publisher_id => @publisher.to_param
    
    assert_response :success
    assert_theme_layout "cnhi/layouts/advertisers/public_index"    
    assert_template "themes/cnhi/advertisers/public_index"
  end
  
  test "CNHI using withtheme for public_index with map" do
    @publishing_group = Factory(:publishing_group, :label => 'cnhi')
    @publisher        = Factory(:publisher, :label => "cnhi-lakeoconeebreeze", :publishing_group => @publishing_group, :theme => "withtheme", :production_host => "localhost")
    get :public_index, :publisher_id => @publisher.to_param, :with_map => true
    
    assert_response :success
    assert_theme_layout "cnhi/layouts/advertisers/public_index"    
    assert_template "themes/cnhi/advertisers/map_index"
  end  

  context "advertisers controller api actions" do
    setup do
      Time.stubs(:now).returns(Time.parse("Jan 01, 2011 01:00:00 UTC"))
      @advertiser = Factory(:advertiser, { :name => "Mamas Pizza", :landing_page => "http://www.google.com" })
    end
    
    should "return failure for show.json if the API-Version request header is missing" do
      get :show, :id => @advertiser.to_param, :format => "json"
      assert_response :not_acceptable
      assert_equal Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
      assert_equal [{ "API-Version" => "is not valid" }], ActiveSupport::JSON.decode(@response.body)
    end
  
    should "return failure for show.json if the API-Version request header is wrong" do
      @request.env['API-Version'] = "9.9.9"
      get :show, :id => @advertiser.to_param, :format => "json"
      assert_response :not_acceptable
      assert_equal Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
      assert_equal [{ "API-Version" => "is not valid" }], ActiveSupport::JSON.decode(@response.body)
    end
  
    should "have correct JSON response for show.json (v 1.0.0)" do
      @request.env['API-Version'] = "1.0.0"
      get :show, :id => @advertiser.to_param, :format => 'json'
      assert_response :success
      assert_equal "1.0.0", @response.headers["API-Version"]
      
      expected = {
        "name" => "Mamas Pizza",
        "updated_at" => "2011-01-01T01:00:00Z",
        "logo" => @advertiser.logo.url,
        "website" => @advertiser.website_url,
        "locations" => [{
          "id" => @advertiser.stores.first.id,
          "name" => nil,
          "address_line_1" => "3005 South Lamar", "address_line_2" => "Apt 1", "city" => "Austin", "state" => "TX", "zip" => "78704", "country" => "US", 
          "latitude" => 45.5381, "longitude" => -121.567, "phone_number" => @advertiser.stores.first.phone_number.to_s
        }],
        "connections" => {
          "publisher" => "http://#{AppConfig.api_host}/publishers/#{@advertiser.publisher.label}.json"
        }
      }
      assert_equal expected, ActiveSupport::JSON.decode(@response.body)
    end
    
    should "have correct JSON response for show.json (v 2.0.0)" do
      @request.env['API-Version'] = "2.0.0"
      get :show, :id => @advertiser.to_param, :format => 'json'
      assert_response :success
      assert_equal "2.0.0", @response.headers["API-Version"]
      
      expected = {
        "name" => "Mamas Pizza",
        "updated_at" => "2011-01-01T01:00:00Z",
        "logo" => @advertiser.logo.url,
        "website" => @advertiser.website_url,
        "locations" => [{
          "id" => @advertiser.stores.first.id,
          "name" => nil,
          "address_line_1" => "3005 South Lamar", "address_line_2" => "Apt 1", "city" => "Austin", "state" => "TX", "zip" => "78704", "country" => "US",
          "latitude" => 45.5381,"longitude" => -121.567, "phone_number" => @advertiser.stores.first.phone_number.to_s
        }],
        "connections" => {
          "publisher" => "http://#{AppConfig.api_host}/publishers/#{@advertiser.publisher.label}.json"
        }
      }
      assert_equal expected, ActiveSupport::JSON.decode(@response.body)
    end
    
    should "return not found for invalid advertiser id (v 1.0.0)" do
      @request.env['API-Version'] = "1.0.0"
      get :show, :id => 9999, :format => 'json'
      assert_response :not_found
    end
    
    should "return not found for invalid advertiser id (v 2.0.0)" do
      @request.env['API-Version'] = "2.0.0"
      get :show, :id => 9999, :format => 'json'
      assert_response :not_found
    end
  end

  context "publishing_group has uses_paychex set" do
    setup do
      @publisher.publishing_group.update_attributes(
        :uses_paychex => true,
        :paychex_initial_payment_percentage => 80.0,
        :paychex_num_days_after_which_full_payment_released => 44
      )
    end

    context "#edit" do
      should "show advertiser edit field on GET edit" do
        @advertiser = Factory(:advertiser, :publisher => @publisher)

        check_result = lambda do |role|
          assert_select "input[name='advertiser[id]'][disabled='disabled']", 1
        end

        with_login_managing_publisher_required(@publisher, check_result) do
          get :edit, :id => @advertiser.id
        end
      end

    end

    context "#new" do
      setup do
        login_as Factory(:admin)
      end

      should "not show advertiser edit field on GET new" do
        check_result = lambda do |role|
          assert_select "input[name='advertiser[id]']", 0
        end

        with_login_managing_publisher_required(@publisher, check_result) do
          get :new, :publisher_id => @publisher.id
        end
      end

      should "add a new store to @advertiser.stores" do
        get :new, :publisher_id => @publisher.to_param
        assert_response :ok
        assert assigns(:advertiser).new_record?
        assert assigns(:advertiser).stores.first.new_record?
      end
    end

    context "#create" do
      setup do
        login_as Factory(:admin)
      end

      should "add a new store to @advertiser.stores" do
        post :create, :publisher_id => @publisher.to_param, :advertiser => {:email_address => "blah"}
        assert_response :ok
        assert assigns(:advertiser).new_record?
        assert assigns(:advertiser).stores.first.new_record?
      end
    end
  end
end

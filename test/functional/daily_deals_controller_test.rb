require File.dirname(__FILE__) + "/../test_helper"

class DailyDealsControllerTest < ActionController::TestCase
  setup :assign_valid_attributes

  def assign_valid_attributes
    @valid_attributes = self.class.get_valid_attributes
  end

  def self.get_valid_attributes
    {
      :value_proposition => "$25 value for $12.99",
      :description => "This is a daily deal. Enjoy!",
      :terms => "These are the terms. Obey!",
      :quantity => 100,
      :min_quantity => 1,
      :price => 12.99,
      :value => 25.00,
      :start_at => 10.days.ago,
      :hide_at => Time.zone.now.tomorrow,
      :upcoming => true,
      :account_executive => "Bob Mann"
    }
  end

  context "an unauthenticated user" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
    end

    should "NOT be able to view index" do
      get_index_results_in_redirect_to_login
    end

    should "NOT be able to view new daily deal page" do
      get_new_results_in_redirect_to_login
    end

    should "NOT be able to view edit daily deal page" do
      get_edit_results_in_redirect_to_login
    end

    should "NOT be able to create daily deal" do
      post_create_results_in_redirect_to_login
    end

    should "NOT be able to update daily deal" do
      post_update_results_in_redirect_to_login
    end

    should "NOT be able to destroy daily deal" do
      post_destroy_results_in_redirect_to_login
    end

    should "be able to view public daily deal" do
      daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
      get :show, :id => daily_deal.to_param
      assert_response :success
      assert_template :show
      assert_layout :daily_deals
    end

    should "be able to view daily deal if daily_deal show on landing_page and publisher enable redirect to landing if deal not shown on landing page" do
      daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser, :show_on_landing_page => true)

      get :show, :id => daily_deal.to_param

      assert_response :success
      assert_template :show
      assert_layout :daily_deals
      assert_nil flash[:notice]
    end


    should "redirect to main publisher in publishing group" do
      main_publisher = @publisher.publishing_group.main_publisher

      daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)

      get :show, :id => daily_deal.to_param
      assert_nil flash[:notice]
    end
  end

  context "a user without admin privilege" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @non_admin_user = Factory :user_without_company
    end

    should "NOT be able to view index" do
      login_as @non_admin_user
      get_index_results_in_redirect_to_login
    end

    should "NOT be able to view new daily deal page" do
      login_as @non_admin_user
      get_new_results_in_redirect_to_login
    end

    should "NOT be able to view edit daily deal page" do
      login_as @non_admin_user
      get_edit_results_in_redirect_to_login
    end

    should "NOT be able to create daily deal" do
      login_as @non_admin_user
      post_create_results_in_redirect_to_login
    end

    should "NOT be able to update daily deal" do
      login_as @non_admin_user
      post_update_results_in_redirect_to_login
    end

    should "NOT be able to destroy daily deal" do
      login_as @non_admin_user
      post_destroy_results_in_redirect_to_login
    end

  end

  context "a user not belonging to self service publisher" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @another_publisher = Factory(:publisher, :self_serve => true)
      @unauthorized_user = Factory(:user, :company => @another_publisher)
    end

    should "NOT be able to view index" do
      login_as @unauthorized_user
      get_index_results_in_record_not_found
    end

    should "NOT be able to view new daily deal page" do
      login_as @unauthorized_user
      get_new_results_in_record_not_found
    end

    should "NOT be able to view edit daily deal page" do
      login_as @unauthorized_user
      get_edit_results_in_record_not_found
    end

    should "NOT be able to create daily deal" do
      login_as @unauthorized_user
      post_create_results_in_record_not_found
    end

    should "NOT be able to update daily deal" do
      login_as @unauthorized_user
      post_update_results_in_record_not_found
    end

    should "NOT be able to destroy daily deal" do
      login_as @unauthorized_user
      post_destroy_results_in_record_not_found
    end

  end

  context "a user belonging to non self service publisher" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @another_publisher = Factory(:publisher)
      @unauthorized_user = Factory(:user, :company => @another_publisher)
    end

    should "NOT be able to view index" do
      login_as @unauthorized_user
      get_index_results_in_record_not_found
    end

    should "NOT be able to view new daily deal page" do
      login_as @unauthorized_user
      get_new_results_in_record_not_found
    end

    should "NOT be able to view edit daily deal page" do
      login_as @unauthorized_user
      get_edit_results_in_record_not_found
    end

    should "NOT be able to create daily deal" do
      login_as @unauthorized_user
      post_create_results_in_record_not_found
    end

    should "NOT be able to update daily deal" do
      login_as @unauthorized_user
      post_update_results_in_record_not_found
    end

    should "NOT be able to destroy daily deal" do
      login_as @unauthorized_user
      post_destroy_results_in_record_not_found
    end

  end

  context "a user not belonging to advertiser" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true, :advertiser_self_serve => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @another_advertiser = Factory(:advertiser, :publisher => @publisher)
      @unauthorized_user = Factory(:user, :company => @another_advertiser)
    end

    should "NOT be able to view index" do
      login_as @unauthorized_user
      get_index_results_in_record_not_found
    end

    should "NOT be able to view new daily deal page" do
      login_as @unauthorized_user
      get_new_results_in_record_not_found
    end

    should "NOT be able to view edit daily deal page" do
      login_as @unauthorized_user
      get_edit_results_in_record_not_found
    end

    should "NOT be able to create daily deal" do
      login_as @unauthorized_user
      post_create_results_in_record_not_found
    end

    should "NOT be able to update daily deal" do
      login_as @unauthorized_user
      post_update_results_in_record_not_found
    end

    should "NOT be able to destroy daily deal" do
      login_as @unauthorized_user
      post_destroy_results_in_record_not_found
    end

  end

  context "a user belonging to a non self service advertiser" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @unauthorized_user = Factory(:user, :company => @advertiser)
    end

    should "NOT be able to view index" do
      login_as @unauthorized_user
      get_index_results_in_record_not_found
    end

    should "NOT be able to view new daily deal page" do
      login_as @unauthorized_user
      get_new_results_in_record_not_found
    end

    should "NOT be able to view edit daily deal page" do
      login_as @unauthorized_user
      get_edit_results_in_record_not_found
    end

    should "NOT be able to create daily deal" do
      login_as @unauthorized_user
      post_create_results_in_record_not_found
    end

    should "NOT be able to update daily deal" do
      login_as @unauthorized_user
      post_update_results_in_record_not_found
    end

    should "NOT be able to destroy daily deal" do
      login_as @unauthorized_user
      post_destroy_results_in_record_not_found
    end

  end

  context "an admin user" do

    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @admin_user = Factory(:admin)
    end

    should "be able to view index" do
      login_as @admin_user
      get_index_with_success
    end

    should "be able to view new daily deal page" do
      login_as @admin_user
      get_new_with_success
    end

    should "be able to view edit daily deal page" do
      login_as @admin_user
      get_edit_with_success
    end

    should "be able to see the cobranding checkbox on the deal edit page" do
      login_as @admin_user
      daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
      get :edit, :id => daily_deal.to_param
      assert_response :success
      assert_template :edit
      assert_select "input#daily_deal_cobrand_deal_vouchers[type=checkbox]", :count => 1
    end

    should "be able to download the deal qr code on the edit page" do
      login_as @admin_user
      get :edit, :id => Factory(:daily_deal).to_param
      assert_response :success
      assert_select "a#download-qr-code"
    end

    should "be able to create daily deal" do
      login_as @admin_user
      post_create_with_success
    end

    should "be able to update daily deal" do
      login_as @admin_user
      post_update_with_success
    end

    should "be able to destroy daily deal" do
      login_as @admin_user
      post_destroy_with_success
    end

  end

  context "a user belonging to self service publisher" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @authorized_user = Factory(:user, :company => @publisher)
    end

    should "be able to view index" do
      login_as @authorized_user
      get_index_with_success
    end

    should "be able to view new daily deal page" do
      login_as @authorized_user
      get_new_with_success
    end

    should "be able to view edit daily deal page but should not see syndication" do
      login_as @authorized_user
      get_edit_with_success_and_without_syndication
    end

    should "not be able to see the cobranding checkbox" do
      login_as @authorized_user
      daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
      get :edit, :id => daily_deal.to_param
      assert_response :success
      assert_template :edit
      assert_select "input#daily_deal_cobrand_deal_vouchers[type=checkbox]", :count => 0
    end
    
    should "be able to create daily deal" do
      login_as @authorized_user
      post_create_with_success
    end

    should "be able to update daily deal" do
      login_as @authorized_user
      post_update_with_success
    end

    should "be able to destroy daily deal" do
      login_as @authorized_user
      post_destroy_with_success
    end

  end

  context "a user belonging to self service advertiser" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true, :advertiser_self_serve => true)
      @advertiser = Factory(:advertiser, :publisher => @publisher)
      @authorized_user = Factory(:user, :company => @advertiser)
    end

    should "be able to view index" do
      login_as @authorized_user
      get_index_results_in_record_not_found
    end

    should "be able to view new daily deal page" do
      login_as @authorized_user
      get_new_with_success
    end

    should "be able to view edit daily deal page" do
      login_as @authorized_user
      get_edit_with_success_and_without_syndication
    end

    should "be able to create daily deal" do
      login_as @authorized_user
      post_create_with_success
    end

    should "be able to update daily deal" do
      login_as @authorized_user
      post_update_with_success
    end

    should "be able to destroy daily deal" do
      login_as @authorized_user
      post_destroy_with_success
    end

  end

  test "new with valid account" do
    advertiser = advertisers(:changos)

    check_response = lambda { |role|
      assert_template :edit, role
      assert_layout   :application

      assert_select "a#download-qr-code", false
      assert_select "input[type='text'][name='daily_deal[value_proposition]']"
      assert_select "textarea[name='daily_deal[description]']"
      assert_select "input[type='text'][name='daily_deal[price]']"
      assert_select ".last_edited", :count => 0
      assert_select "input[type='text'][name='daily_deal[value]']"
      assert_select "input[type='text'][name='daily_deal[min_quantity]']"
      assert_select "input[type='text'][name='daily_deal[max_quantity]']"
      assert_select "textarea[name='daily_deal[highlights]']"
      assert_select "textarea[name='daily_deal[terms]']"
      assert_select "textarea[name='daily_deal[reviews]']"
      assert_select "textarea[name='daily_deal[voucher_steps]']", :text => advertiser.publisher.default_voucher_steps(advertiser.name)
      assert_select "textarea[name='daily_deal[facebook_title_text]']"
      assert_select "textarea[name='daily_deal[twitter_status_text]']"
      assert_select "textarea[name='daily_deal[short_description]']"
      assert_select "input[name='daily_deal[photo]']"
      assert_select "input[name='daily_deal[start_at]']"
      assert_select "input[name='daily_deal[hide_at]']"
      assert_select "input[name='daily_deal[expires_on]']"
      assert_select "input[name='daily_deal[tipping_point]']", :count => 0
      assert_select "input[name='daily_deal[listing]']"
      assert_select "input[type='text'][name='daily_deal[advertiser_revenue_share_percentage]']"
      assert_select "input[type='text'][name='daily_deal[advertiser_credit_percentage]']"
      assert_select "input[type='text'][name='daily_deal[account_executive]']"
      assert_select "input[type='checkbox'][name='daily_deal[shopping_mall]']", 0
      assert_select "input[type=checkbox][name='daily_deal[enable_daily_email_blast]']"
      assert_select "input[type=checkbox][name='daily_deal[hide_serial_number_if_bar_code_is_present]']"
      assert_select "input[type=checkbox][name='daily_deal[voucher_has_qr_code]']"
      assert_select "input[type=checkbox][name='daily_deal[available_for_syndication]']", 0
      assert_select "input[type=checkbox][name='daily_deal[national_deal]']"
      assert_select "input[type=checkbox][name='daily_deal[requires_shipping_address]']"
      assert_select "label", :text => "Syndicated to Publishers:", :count => 0
      assert_select "textarea[name='daily_deal[email_voucher_redemption_message]']", :text => "Please bring your printed voucher and valid photo ID when you go to redeem your deal at #{advertiser.try :name}."
      assert_select "input[type='text'][name='daily_deal[custom_1]']"
      assert_select "input[type='text'][name='daily_deal[custom_2]']"
      assert_select "input[type='text'][name='daily_deal[custom_3]']"
      assert_select "input[type='checkbox'][name='daily_deal[qr_code_active]']"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :new, :advertiser_id => advertiser.to_param
    end
  end

  test "new with valid account with allow_secondary_daily_deal_photo" do
    advertiser = advertisers(:changos)

    advertiser.publisher.update_attribute(:allow_secondary_daily_deal_photo, true)

    check_response = lambda { |role|
      assert_select "input[name='daily_deal[secondary_photo]']"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :new, :advertiser_id => advertiser.to_param
    end
  end

  test "create with valid attributes" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher

    check_response = lambda { |role|
      assert_redirected_to edit_advertiser_path(advertiser), role
      assert_equal flash[:notice], "Created daily deal for #{advertiser.name}"
      assert_equal 2, Advertiser.find(advertiser.id).daily_deals.size, "should be assigned to advertiser"
      assert_equal publisher, Advertiser.find(advertiser.id).daily_deals.first.publisher, "should assign publisher"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      DailyDeal.destroy_all
      post :create, :advertiser_id => advertiser.to_param, :daily_deal => @valid_attributes
    end
  end

  test "create with valid attributes and bar codes" do
    publisher = Factory(:publisher)
    advertiser = Factory(:advertiser, :publisher => publisher)
    user = Factory(:admin)
    csv_stream = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/bar_codes.csv", 'text/csv')
    login_as user
    post :create, :advertiser_id => advertiser.to_param,
      :daily_deal => {
        :value_proposition => "$25 value for $13",
        :description => "A description, yay",
        :terms => "Some terms for you",
        :quantity => 100,
        :min_quantity => 1,
        :price => 12.99,
        :value => 25.00,
        :start_at => 10.days.ago,
        :hide_at => Time.zone.now.tomorrow,
        :upcoming => true,
        :account_executive => "Steve Guy",
        :bar_code_encoding_format => 7,
        :bar_codes_csv => csv_stream,
        :delete_existing_unassigned_bar_codes => "0",
        :allow_duplicate_bar_codes => "0"
      }
    assert_redirected_to edit_advertiser_path(advertiser)
    deal = advertiser.daily_deals.first
    assert_equal 2, deal.bar_codes.size, "should have 2 bar codes now"
  end

  test "create with available_for_syndication" do
    publisher  = Factory(:publisher, :in_syndication_network => true)
    advertiser = Factory(:advertiser, :publisher => publisher)
    user = Factory(:admin)
    login_as user
    post :create, 
         :advertiser_id => advertiser.to_param,
         :daily_deal => {
           :value_proposition => "$25 value for $12.99",
           :description => "This is a daily deal. Enjoy!",
           :terms => "These are the terms. Obey!",
           :quantity => 100,
           :min_quantity => 1,
           :price => 12.99,
           :value => 25.00,
           :start_at => 10.days.ago,
           :hide_at => Time.zone.now.tomorrow,
           :upcoming => true,
           :account_executive => "Bob Mann",
           :available_for_syndication => true
         }
    assert_redirected_to edit_advertiser_path(advertiser)
    assert_equal flash[:notice], "Created daily deal for #{advertiser.name}"
    assert advertiser.daily_deals.any?, "should create a deal"
    deal = advertiser.daily_deals.first
    assert_equal publisher, deal.publisher, "should assign publisher"
    assert_equal true, deal.available_for_syndication?, "should assign available for syndication"
  end
  
  test "create with invalid attributes" do
    advertiser = advertisers(:changos)
    advertiser.daily_deals.destroy_all
    check_response = lambda { |role|
      assert_template :edit, role
      assert !assigns(:daily_deal).errors.empty?
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      post :create, :advertiser_id => advertiser.to_param, :daily_deal => {}
    end
  end

  test "create with short description character limit ignored" do
    publisher  = Factory(:publisher, :ignore_daily_deal_short_description_size => true)
    advertiser = Factory(:advertiser, :publisher => publisher)

    login_as Factory(:admin)

    daily_deal = {
      :short_description => "This is longer than 50 characters of text and I hope the test passes!"
    }.merge(@valid_attributes)

    assert_difference 'DailyDeal.count' do
      post :create, :advertiser_id => advertiser.to_param, :daily_deal => daily_deal

      assert_redirected_to edit_advertiser_path(advertiser)
      assert assigns(:daily_deal).errors.empty?
    end
  end

  test "create with publisher.allow_admins_to_edit_advertiser_revenue_share_percentage to false as admin" do
    publisher  = Factory(:publisher, :allow_admins_to_edit_advertiser_revenue_share_percentage => false)
    advertiser = Factory(:advertiser, :publisher => publisher)

    login_as Factory(:admin)

    daily_deal = {
      :advertiser_revenue_share_percentage => 2
    }.merge(@valid_attributes)

    assert_no_difference 'DailyDeal.count' do
      post :create, :advertiser_id => advertiser.to_param, :daily_deal => daily_deal

      assert_template :edit
      assert !assigns(:daily_deal).errors.empty?
    end

    daily_deal.delete(:advertiser_revenue_share_percentage)

    assert_difference 'DailyDeal.count' do
      post :create, :advertiser_id => advertiser.to_param, :daily_deal => daily_deal

      assert_redirected_to edit_advertiser_path(advertiser)
      assert assigns(:daily_deal).errors.empty?
    end
  end

  test "create with publisher.allow_admins_to_edit_advertiser_revenue_share_percentage to false as publisher user" do
    publisher   = Factory :publisher,
                          :allow_admins_to_edit_advertiser_revenue_share_percentage => false,
                          :advertiser_self_serve => true
    advertiser  = Factory :advertiser, :publisher => publisher
    daily_deal  = { :advertiser_revenue_share_percentage => 2 }.merge(@valid_attributes)
    daily_deal2 = { :side_start_at => @valid_attributes[:start_at], :side_end_at => @valid_attributes[:hide_at] }.merge(@valid_attributes)

    login_as Factory :user, :company => advertiser

    [ daily_deal, daily_deal2 ].each do |dd|
      assert_difference 'DailyDeal.count' do
        post :create, :advertiser_id => advertiser.to_param, :daily_deal => dd
        assert assigns(:daily_deal).errors.empty?
      end
    end
  end
  
  test "update with valid attributes" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes.merge(:affiliate_revenue_share_percentage => 23, :affiliate_url => 'http://www.google.com/'))
    user = Factory(:admin)
    login_as user
    post :update, :advertiser_id => advertiser.to_param, :id => daily_deal.to_param,
      :daily_deal => {
        :description => "New Description",
        :affiliate_revenue_share_percentage => "",
        :affiliate_url => "http://www.yahoo.com/",
        :advertiser_credit_percentage => 2,
        :shipping_address_message => (sa_msg = 'message not in the factory')
      }
    assert_redirected_to edit_daily_deal_path(daily_deal)
    daily_deal.reload
    assert_equal "New Description", daily_deal.description_plain
    assert_nil daily_deal.affiliate_revenue_share_percentage
    assert_equal "http://www.yahoo.com/", daily_deal.affiliate_url
    assert_equal 2.0, daily_deal.advertiser_credit_percentage
    assert_equal true, daily_deal.upcoming
    assert_equal advertiser, daily_deal.advertiser
    assert_equal sa_msg, daily_deal.shipping_address_message

  end

  test "update with invalid attributes" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    user = Factory(:admin)
    login_as user
    post :update, :id => daily_deal.to_param, :daily_deal => {:price => ""}
    assert_template :edit
    assert !assigns(:daily_deal).errors.empty?
  end

  test "update with invalid affiliate_url" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    user = Factory(:admin)
    login_as user
    post :update, :id => daily_deal.to_param, :daily_deal => {:affiliate_url => "bogus url"}
    assert_template :edit
    assert !assigns(:daily_deal).errors.empty?
  end

  test "update without bit ly url" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    DailyDeal.connection.execute "update daily_deals set bit_ly_url=NULL where id=#{daily_deal.id}"
    daily_deal = DailyDeal.find(daily_deal.id)
    assert_nil daily_deal.bit_ly_url, "bit_ly_url"
    user = Factory(:admin)
    login_as user
    post :update, :id => daily_deal.to_param, :daily_deal => {:description => "New Description"}
    assert_redirected_to edit_daily_deal_path(daily_deal)
    assert_equal "New Description", daily_deal.reload.description_plain
    assert_equal advertiser, daily_deal.reload.advertiser
  end

  context "destroy" do
    setup do
      @publishers = Factory(:publisher)
      @advertiser = Factory(:advertiser)
      @daily_deal = Factory(:daily_deal, :publisher => @publishers, :advertiser => @advertiser)
      @user = Factory(:admin)
    end

    should "redirect to edit advertisers path if referred through advertiser" do
      login_as @user
      @request.env['HTTP_REFERER'] = "/advertisers/#{@advertiser.id}/edit"
      delete :destroy, :id => @daily_deal.to_param
      assert_redirected_to edit_advertiser_path(@daily_deal.advertiser)
      assert_equal "Daily Deal was deleted.", flash[:notice]
      assert DailyDeal.find(@daily_deal.id).deleted?
    end

    should "redirect to publisher daily deals path if referred through publishers" do
      login_as @user
      @request.env['HTTP_REFERER'] = "/publishers/#{@publishers.id}/daily_deals"
      delete :destroy, :id => @daily_deal.to_param
      assert_redirected_to publisher_daily_deals_path(@daily_deal.publisher)
      assert_equal "Daily Deal was deleted.", flash[:notice]
      assert DailyDeal.find(@daily_deal.id).deleted?
    end

    should "redirect to publisher daily deals if no referrer" do
      login_as @user
      delete :destroy, :id => @daily_deal.to_param
      assert_redirected_to publisher_daily_deals_path(@daily_deal.publisher)
      assert_equal "Daily Deal was deleted.", flash[:notice]
      assert DailyDeal.find(@daily_deal.id).deleted?
    end
  end

  test "clear photo" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    daily_deal.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    daily_deal.save!

    @request.session[:user_id] = users(:aaron)
    xhr :post, :clear_photo, :id => daily_deal.to_param
    assert_response :success

    # Get latest attachment state from DB
    daily_deal = DailyDeal.find(daily_deal.id)
    assert !daily_deal.photo.file?, "Should remove photo image file"
  end

  test "clear photo on syndicated deals" do
    distributed_publisher = Factory.create(:publisher)
    user = Factory.create(:user, :company => distributed_publisher)
    daily_deal = Factory.create(:daily_deal_for_syndication)
    daily_deal.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    syndicated_deal = daily_deal.syndicated_deals.build(:publisher_id => distributed_publisher.id)
    daily_deal.save!

    login_as user
    xhr :post, :clear_photo, :id => syndicated_deal.to_param
    assert_response :success

    syndicated_deal.reload
    assert !syndicated_deal.photo.file?, "Should remove photo image file from the syndicated deal"
    assert daily_deal.photo.file?, "Should not remove photo image file from the source deal"
  end

  test "clear secondary photo" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    daily_deal.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    daily_deal.secondary_photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    daily_deal.save!

    login_as users(:aaron)
    xhr :post, :clear_secondary_photo, :id => daily_deal.to_param
    assert_response :success

    daily_deal = DailyDeal.find(daily_deal.id) # reload isn't enough
    assert daily_deal.photo.file?, "Should not remove photo image file"
    assert !daily_deal.secondary_photo.file?, "Should remove secondary photo image file"
  end

  test "clear secondary photo on syndicated deals" do
    distributed_publisher = Factory.create(:publisher)
    user = Factory.create(:user, :company => distributed_publisher)
    daily_deal = Factory.create(:daily_deal)
    daily_deal.update_attribute(:available_for_syndication, true)
    daily_deal.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    daily_deal.secondary_photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    syndicated_deal = daily_deal.syndicated_deals.build(:publisher_id => distributed_publisher.id)
    daily_deal.save!

    login_as user
    xhr :post, :clear_secondary_photo, :id => syndicated_deal.to_param
    assert_response :success

    syndicated_deal = DailyDeal.find(syndicated_deal.id) # reload isn't enough
    assert syndicated_deal.photo.file?, "Should not remove photo image file"
    assert !syndicated_deal.secondary_photo.file?, "Should remove secondary photo image file"
    assert daily_deal.photo.file?, "Should not remove photo image file from the source deal"
    assert daily_deal.secondary_photo.file?, "Should not remove secondary photo image file from the source deal"
  end

  test "deliver email" do
    publisher = Factory(:publisher, :name => "LA Daily News", :label => "dailynews")
    advertiser = publisher.advertisers.create!(:name => "Advertiser")
    daily_deal = advertiser.daily_deals.create!(
      :price => 39,
      :value => 80,
      :description => "awesome deal",
      :terms => "GPL",
      :value_proposition => "buy now",
      :start_at => 1.day.ago,
      :hide_at => 3.days.from_now
    )

    login_as :aaron
    get :deliver_email, :label => publisher.label, :to => "admin@example.com"
    assert_response :success
  end

  test "twitter" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    ClickCount.destroy_all

    get :twitter, :id => daily_deal.to_param
    escaped_status = CGI.escape("MySDH.com Deal of the Day: $25 value for $12.99 at Changos ").gsub('+', '%20') + daily_deal.bit_ly_url
    assert_redirected_to %Q{http://twitter.com/?status=#{escaped_status}}
    assert_equal 1, ClickCount.count, "Should generate one click count"
    click_count = ClickCount.first
    assert_equal daily_deal, click_count.clickable, "Click-count daily deal"
    assert_equal 1, click_count.count, "Click-count count"
    assert_equal "twitter", click_count.mode, "Click-count mode"
  end

  test "facebook" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)
    ClickCount.destroy_all

    get :facebook, :id => daily_deal.to_param
    daily_deal_url = daily_deal_url(daily_deal, :v => daily_deal.updated_at.to_i)
    escaped_t = "MySDH.com+Deal+of+the+Day%3A+%2425+value+for+%2412.99"
    assert_redirected_to %Q{http://www.facebook.com/share.php?u=#{CGI.escape(daily_deal_url)}&t=#{escaped_t}}

    assert_equal 1, ClickCount.count, "Should generate one click count"
    click_count = ClickCount.first
    assert_equal daily_deal, click_count.clickable, "Click-count daily deal"
    assert_equal 1, click_count.count, "Click-count count"
    assert_equal "facebook", click_count.mode, "Click-count mode"

  end

  test "index" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    check_response = lambda { |role|
      assert_template :index, role
      assert_layout   :application
      assert_equal    publisher, assigns(:publisher)
      assert_not_nil  assigns(:daily_deals)
    }

    with_login_managing_publisher_required(publisher, check_response) do
      get :index, :publisher_id => publisher.to_param, :id => daily_deal.to_param
    end
  end

  test "subscribe with valid attributes" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    publisher.subscribers.clear
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    @request.env['HTTP_REFERER'] = public_deal_of_day_path(:label => publisher.label)

    post :subscribe, :publisher_id => publisher.to_param, :subscriber => {:email => "test@somewhere.com", :terms => "1"}

    assert_redirected_to subscribed_publisher_daily_deals_path(publisher)
    assert_equal 1, Publisher.find(publisher.id).subscribers.size
    assert_equal "subscribed", cookies['subscribed']
  end

  test "SSL subscriber with valid attributes" do
    ssl_on
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    publisher.subscribers.clear
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    @request.env['HTTP_REFERER'] = public_deal_of_day_path(:label => publisher.label)

    post :subscribe, :publisher_id => publisher.to_param, :subscriber => {:email => "test@somewhere.com", :terms => "1"}

    assert_redirected_to subscribed_publisher_daily_deals_path(publisher)
    assert_equal 1, Publisher.find(publisher.id).subscribers.size
    assert_equal "subscribed", cookies['subscribed']
  end

  test "subscribe with no referrer" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    publisher.subscribers.clear
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    post :subscribe, :publisher_id => publisher.to_param, :subscriber => {:email => "test@somewhere.com", :terms => "1"}

    assert_redirected_to subscribed_publisher_daily_deals_path(publisher)
    assert_equal 1, Publisher.find(publisher.id).subscribers.size
    assert_equal "subscribed", cookies['subscribed']
  end

  test "subscribe without valid attributes" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    publisher.subscribers.clear
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    @request.env['HTTP_REFERER'] = public_deal_of_day_path(:label => publisher.label)

    post :subscribe, :publisher_id => publisher.to_param, :subscriber => {:email => "test@somewhere.com", :terms => "0"}

    assert_redirected_to public_deal_of_day_path(:label => publisher.label)
    assert_equal 0, Publisher.find(publisher.id).subscribers.size
    assert_equal "Enter your email first - then agree to terms - then click SUBSCRIBE.", flash[:warn]
    assert_nil cookies['subscribed']
  end

  test "subscriber with device and user_agent attributes" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    publisher.subscribers.clear
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)"

    post :subscribe, :publisher_id => publisher.to_param, :subscriber => {:device => "tablet", :email => "test@somewhere.com", :terms => "1"}

    assert_redirected_to subscribed_publisher_daily_deals_path(publisher)
    assert_equal 1, Publisher.find(publisher.id).subscribers.size
    assert_equal "subscribed", cookies['subscribed']

    subscriber = Publisher.find(publisher.id).subscribers.last
    assert_equal "tablet", subscriber.device
    assert_equal "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)", subscriber.user_agent

  end

  test "subscribe has missing deal png with 8newsnow" do
    publisher  = Factory(:publisher, :name => '8news', :label=> '8newsnow')
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    post :subscribe, :publisher_id => publisher.to_param, :subscriber => {:email => "test@somewhere.com", :terms => "1"}
    assert_redirected_to subscribed_publisher_daily_deals_path(publisher)

    get :show, :id => daily_deal.to_param
    assert_template "themes/8newsnow/daily_deals/show"
    assert_equal "subscribed", cookies['subscribed']
    assert_select "div.header img", 0
  end

  test "subscribed" do
    publisher = Factory(:publisher)

    get :subscribed, :publisher_id => publisher.to_param
    assert_response :success

    assert @controller.analytics_tag.signup?

    assert_select "a[href=#{public_deal_of_day_path(:label => publisher.label)}]", true
  end

  test "email for freedom with one advertiser location" do
    publishing_group = Factory(:publishing_group, :name => "Freedom", :label => "freedom")
    publisher = Factory(:publisher,:name => "OC Register", :label => "ocregister", :publishing_group => publishing_group)
    advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
    advertiser.stores.create!(:address_line_1 => "123 Main Street", :city => "Laguna Beach", :state => "CA", :zip => "92651")
    daily_deal = advertiser.daily_deals.create!(
      :price => 39,
      :value => 80,
      :description => "awesome deal",
      :terms => "GPL",
      :value_proposition => "buy now",
      :start_at => 1.day.ago,
      :hide_at => 3.days.from_now
    )
    get :email, :label => publisher.label

    assert_response :success
    assert_template "themes/freedom/daily_deals/email"
  end

  test "email for freedom with two advertiser locations" do
    publishing_group = Factory(:publishing_group, :name => "Freedom", :label => "freedom")
    publisher = Factory(:publisher,:name => "OC Register", :label => "ocregister", :publishing_group => publishing_group)
    advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
    advertiser.stores.create!(:address_line_1 => "123 Main Street", :city => "Laguna Beach", :state => "CA", :zip => "92651")
    advertiser.stores.create!(:address_line_1 => "456 Main Street", :city => "Laguna Beach", :state => "CA", :zip => "92652")
    daily_deal = advertiser.daily_deals.create!(
      :price => 39,
      :value => 80,
      :description => "awesome deal",
      :terms => "GPL",
      :value_proposition => "buy now",
      :start_at => 1.day.ago,
      :hide_at => 3.days.from_now
    )
    get :email, :label => publisher.label

    assert_response :success
    assert_template "themes/freedom/daily_deals/email"
    assert_select "div.address", 0
  end

  test "faqs" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    get :faqs, :publisher_id => publisher.id

    assert_response :success
    assert_layout   "daily_deals"
    assert_template "daily_deals/faqs"
  end

  test "seo friendly faqs" do
    publisher = publishers(:houston_press)
    advertiser = publisher.advertisers.create!( :name => "Advertiser", :listing => "mylisting" )
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    location = "Houston"

    assert_equal nil, cookies['publisher_label']
    get :seo_friendly_faqs, :publisher_label => publisher.label, :location => location

    assert_response :success
    assert_equal publisher.label, cookies['publisher_label']
  end

  test "feature your business" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    publisher.update_attributes(:label => "8coupons")
    daily_deal = advertiser.daily_deals.create!(@valid_attributes)

    get :feature_your_business, :publisher_id => publisher.id

    assert_response     :success
    assert_template     "daily_deals/feature_your_business"
    assert_theme_layout "8coupons/layouts/daily_deals"
  end

  test "feature your business with nydailynews" do
    advertiser = advertisers(:changos)
    publisher  = advertiser.publisher
    publisher.update_attributes(:label => "nydailynews")
    category = Factory(:daily_deal_category)
    daily_deal = advertiser.daily_deals.create!(@valid_attributes.merge(:analytics_category => category))

    get :feature_your_business, :publisher_id => publisher.id

    assert_response     :success
    assert_template     "themes/nydailynews/daily_deals/feature_your_business"
    assert_theme_layout "nydailynews/layouts/daily_deals"
  end

  test "how it works" do
    publisher = Factory(:publisher, :label => "ocregister")
    get :how_it_works, :publisher_id => publisher.id
    assert_response :success
  end

  test "show past deals" do
    daily_deal = Factory(:daily_deal, :hide_at => Time.zone.now.yesterday)
    get :past, :label => daily_deal.publisher.label
    assert_response :success
  end

  test "contact page when there is no support phone number" do
    pub = Factory :publisher, :support_email_address => "support@example.com", :support_phone_number => nil
    get :contact, :publisher_id => pub.id
    assert_response :success
    assert_match /Please email.*support@example.com/, @response.body, "should show support email address"
    assert_no_match /or call/, @response.body, "should not show contact phone number text"
  end

  test "contact page when there is a support phone number" do
    pub = Factory :publisher, :support_email_address => "support@example.com", :support_phone_number => "8005551212"
    get :contact, :publisher_id => pub.id
    assert_response :success
    assert_match /Please email.*support@example.com/, @response.body, "should show support email address"
    assert_match /or call.*\(800\) 555-1212/, @response.body, "should show contact phone number text"
  end

  context "adding a daily deal whose publisher is in the Mountain time zone" do

    setup do
      save_current_time_zone
      Time.zone = nil
      setup_deal_with_publisher_in_time_zone("Mountain Time (US & Canada)")
      get :new, :advertiser_id => @advertiser.id
    end

    should respond_with :success

    should "display the time zone beside each of the editable date/time fields" do
      %w(start_at hide_at expires_on).each do |s|
        assert_select "div##{s}_help", :text => "Mountain Time (US &amp; Canada)"
      end
    end

    teardown do
      restore_saved_time_zone
    end

  end

  context "creating a daily deal whose publisher is in the Mountain time zone" do

    setup do
      save_current_time_zone
      Time.zone = nil
      setup_deal_with_publisher_in_time_zone("Mountain Time (US & Canada)")
      post :create, :advertiser_id => @advertiser.id,
           :daily_deal => Factory.attributes_for(:daily_deal,
                                                 :publisher_id => @publisher_in_time_zone.id,
                                                 :advertiser_id => @advertiser.id,
                                                 :value_proposition => "time zones when creating a deal",
                                                 :start_at => "December 7, 2010 10:35 AM",
                                                 :hide_at => "December 8, 2010 12:00 AM")
    end

    should respond_with :redirect

    should "create the deal in the Mountain time zone" do
      daily_deal = DailyDeal.find_by_value_proposition("time zones when creating a deal")
      assert_equal "2010-12-07 17:35:00", daily_deal.start_at_before_type_cast
      assert_equal "2010-12-08 07:00:00", daily_deal.hide_at_before_type_cast
    end

    teardown do
      restore_saved_time_zone
    end

  end

  context "listing daily deals for a publisher in the Central time zone" do

    setup do
      save_current_time_zone
      Time.zone = nil
      setup_deal_with_publisher_in_time_zone("Central Time (US & Canada)")
      get :index, :publisher_id => @publisher_in_time_zone.id
    end

    should respond_with :success

    should "list deal times in the publisher's time zone" do
      assert_select "td.date", :text => "06/14/10 02:00AM CDT / 06/14/10 09:00PM CDT"
    end

    teardown do
      restore_saved_time_zone
    end

  end

  test "new displays upcoming flag default unchecked" do
    publisher = Factory(:publisher, :label => "entercom-buffalo")
    advertiser = Factory(:advertiser, :name => "Tanning Bed", :publisher => publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)
    user = Factory(:admin)

    assert_equal daily_deal.upcoming, false

    login_as user
    get :new, :id => daily_deal.to_param, :advertiser_id => advertiser.to_param
    assert_response :success
    assert_select "input[type=checkbox][name='daily_deal[upcoming]']"
  end

  test "affiliate as non affiliate user" do
    user = Factory(:user)
    login_as user
    get :affiliate, :publisher_id => user.publisher.id
    assert_response :unauthorized
  end

  test "affiliate" do
    daily_deal  = Factory(:daily_deal, :affiliate_revenue_share_percentage => 2, :start_at => 1.day.ago)
    publisher   = daily_deal.publisher
    daily_deal2 = Factory(:daily_deal, :publisher => publisher, :start_at => 3.days.ago, :hide_at => 2.days.ago )
    affiliate   = Factory(:affiliate, :publisher => publisher)

    login_as affiliate

    get :affiliate, :publisher_id => publisher.id

    assert_template 'daily_deals/affiliate'
    assert_response :success
    assert_equal daily_deal, assigns(:daily_deal), "@daily_deal"
  end

  protected

  def setup_deal_with_publisher_in_time_zone(time_zone = "Eastern Time (US & Canada)")
    @publisher_in_time_zone = Factory(:publisher, :time_zone => time_zone)
    @advertiser = Factory(:advertiser, :publisher_id => @publisher_in_time_zone.id)
    @daily_deal = Factory(:daily_deal,
                          :advertiser_id => @advertiser.id,
                          :start_at => "2010-06-14 07:00:00 UTC",
                          :hide_at => "2010-06-15 02:00:00 UTC",
                          :expires_on => "2010-12-31")
    @admin_user = Factory(:admin)
    @controller.stubs(:current_user).returns(@admin_user)
  end

  def save_current_time_zone
    @original_tz = Time.zone
  end

  def restore_saved_time_zone
    Time.zone = @original_tz
  end

  def get_index_with_success
     get :index, :publisher_id => @publisher.to_param
     assert_response :success
     assert_template :index
  end

  def get_new_with_success
     get :new, :advertiser_id => @advertiser.to_param
     assert_response :success
     assert_template :edit
  end

  def get_edit_with_success
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    get :edit, :id => @daily_deal.to_param
    assert_response :success
    assert_template :edit
  end

  def post_create_with_success
    @daily_deal = Factory.build(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    post :create, :advertiser_id => @advertiser.to_param, :daily_deal => @daily_deal.attributes
    assert_redirected_to edit_advertiser_path(@advertiser)
  end

  def post_update_with_success
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    attributes = @daily_deal.attributes.except("start_at", "price", "hide_at") # remove fields that may become locked, start_at, price, and hide_at
    post :update, :advertiser_id => @advertiser.to_param, :id => @daily_deal.to_param, :daily_deal => attributes
    assert_redirected_to edit_daily_deal_path(@daily_deal)
  end

  def post_destroy_with_success
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    post :destroy, :id => @daily_deal.to_param
    assert_response 302 #test this conditional redirect in a test "destroy"
    assert_equal "Daily Deal was deleted.", flash[:notice]
  end

  def get_new_results_in_redirect_to_login
    get :new, :advertiser_id => @advertiser.to_param
    assert_redirected_to new_session_path
  end

  def get_index_results_in_redirect_to_login
    get :index, :publisher_id => @publisher.to_param
    assert_redirected_to new_session_path
  end

  def get_edit_results_in_redirect_to_login
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    get :edit, :id => @daily_deal.to_param
    assert_redirected_to new_session_path
  end

  def post_create_results_in_redirect_to_login
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    post :create, :advertiser_id => @advertiser.to_param, :daily_deal => @daily_deal
    assert_redirected_to new_session_path
  end

  def post_update_results_in_redirect_to_login
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    post :update, :id => @daily_deal.to_param
    assert_redirected_to new_session_path
  end

  def post_destroy_results_in_redirect_to_login
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    post :destroy, :id => @daily_deal.to_param
    assert_redirected_to new_session_path
  end

  def get_index_results_in_record_not_found
    assert_raises(ActiveRecord::RecordNotFound) do
      get :index, :publisher_id => @publisher.to_param
    end
  end

  def get_new_results_in_record_not_found
    assert_raises(ActiveRecord::RecordNotFound) do
      get :new, :advertiser_id => @advertiser.to_param
    end
  end

  def get_index_results_in_record_not_found
    assert_raises(ActiveRecord::RecordNotFound) do
      get :index, :publisher_id => @publisher.to_param
    end
  end

  def get_edit_results_in_record_not_found
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    assert_raises(ActiveRecord::RecordNotFound) do
      get :edit, :id => @daily_deal.to_param
    end
  end

  def post_create_results_in_record_not_found
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    assert_raises(ActiveRecord::RecordNotFound) do
      post :create, :advertiser_id => @advertiser.to_param, :daily_deal => @daily_deal.attributes
    end
  end

  def post_update_results_in_record_not_found
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    assert_raises(ActiveRecord::RecordNotFound) do
      post :update, :id => @daily_deal.to_param, :daily_deal => @daily_deal.attributes
    end
  end

  def post_destroy_results_in_record_not_found
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    assert_raises(ActiveRecord::RecordNotFound) do
      post :destroy, :id => @daily_deal.to_param
    end
  end

  def get_edit_with_success_and_without_syndication
    @daily_deal = Factory(:daily_deal, :publisher => @publisher, :advertiser => @advertiser)
    get :edit, :id => @daily_deal.to_param
    assert_response :success

    assert_template :edit
    assert_layout :application
    assert_select "label", :count => 1, :text => "Syndicated to Publishers:"
    assert_select "a[href=?]", daily_deal_syndicated_deals_path(@daily_deal), :count => 0, :text => "Syndicate"
  end

  context "daily deal placed by an affiliate" do
    setup do
      Time.stubs(:now).returns(Time.parse("Jan 01, 2011 12:34:56 PST"))
      @daily_deal = Factory(:daily_deal, :start_at => Time.parse("Jan 02, 2011 00:00:00 PST"), :hide_at => Time.parse("Jan 02, 2011 23:55:00 PST"))
      @publisher = Factory(:publisher)
      @uuid = "981fd800-15e6-11e0-baaf-000c29776397"
      @daily_deal.affiliate_placements.create! :affiliate => @publisher, :uuid => @uuid
    end

    should "fail to return the placed deal without HTTP Basic authentication header" do
      get :affiliated, :type => "json"
      assert_response :unauthorized
    end

    context "with HTTP Basic authentication as the affiliated user" do
      setup do
        @user = Factory(:user, :company => @publisher)
        set_http_basic_authentication :name => @user.login, :pass => "test"
      end

      should "allow ssl" do
        ssl_on
        get :affiliated, :type => "json"
      end

      should "return the placed daily deal" do
        get :affiliated, :type => "json"
        assert_response :success

        hash = ActiveSupport::JSON.decode(@response.body)
        assert_equal [@daily_deal.uuid], hash.keys

        deal = hash[@daily_deal.uuid]
        assert_equal  15.0, deal["price"]
        assert_equal  30.0, deal["value"]
        assert_equal "$30.00 for only $15.00!", deal["title"]
        assert_equal "2011-01-01T20:34:56Z", deal["updated_at"]
        assert_equal "2011-01-02T08:00:00Z", deal["starts_at"]
        assert_equal "2011-01-03T07:55:00Z", deal["ends_at"]
        assert_equal "<p>this is my description</p>", deal["description"]
        assert_equal "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.to_param}?placement_code=#{@uuid}", deal["deal_url"]

        originator = deal["originator"]
        assert_equal @daily_deal.publisher.name, originator["brand_name"]
        assert_equal @daily_deal.publisher.logo.url, originator["logo_url"]

        merchant = deal["merchant"]
        assert_equal @daily_deal.advertiser.name, merchant["brand_name"]
        assert_equal @daily_deal.advertiser.logo.url, merchant["logo_url"]

        expected_location = {
          "name" => nil,
          "address_line_1" => "3005 South Lamar",
          "address_line_2" => "Apt 1",
          "city" => "Austin",
          "state" => "TX",
          "zip" => "78704",
          "country" => "US",
          "latitude" => 45.5381,
          "longitude" => -121.567
        }
        assert_equal [expected_location], merchant["locations"]
      end

      should "request basic auth again when the account is locked" do
        @user.lock_access!
        get :affiliated, :type => "json"
        assert_response :unauthorized
      end
    end
  end

  context "GET to #affiliated_publisher_list" do
    setup do
      @admin = Factory :admin
      @affiliate_placement = Factory :affiliate_placement
    end

    should "be visible only to admin users" do
      get :affiliated_publisher_list, :id => @affiliate_placement.placeable.id
      assert_response :redirect
      assert_redirected_to new_session_url
    end

    should "render the daily_deals/_affiliate_placements.html.erb partial with no layout" do
      @controller.stubs(:current_user).returns(@admin)
      get :affiliated_publisher_list, :id => @affiliate_placement.placeable.id
      assert_response :success
      assert_template "daily_deals/_affiliate_placements.html.erb"
      assert_layout nil
    end

  end

  test "about_us" do
    publishing_group = Factory(:publishing_group, :label => "rr")
    publisher = Factory(:publisher, :label => "clickedin-austin", :publishing_group => publishing_group)

    get :about_us, :publisher_id => publisher.id

    assert_response :success
    assert_template "themes/rr/daily_deals/about_us"
    assert_theme_layout "rr/layouts/daily_deals"
  end

  test "about us render consumer's publisher with enable redirect to local static page" do
    publishing_group = Factory(:publishing_group, :label => "rr", :enable_redirect_to_local_static_pages => true)
    publisher = Factory(:publisher, :label => 'clickedin-austin', :publishing_group => publishing_group)

    consumer  = Factory(:consumer, :publisher => publisher)
    other_publisher = Factory(:publisher, :label => 'clickedin-sanantonio', :publishing_group => publishing_group)

    login_as consumer
    get :about_us, :publisher_id => other_publisher.id

    assert_equal(publisher.id, assigns(:publisher).id)
    assert_response :success
  end

  test "about us render publisher without enable redirect to local static page" do
    publishing_group = Factory(:publishing_group, :label => "rr", :enable_redirect_to_local_static_pages => false)
    publisher = Factory(:publisher, :label => 'clickedin-austin', :publishing_group => publishing_group)

    consumer  = Factory(:consumer, :publisher => publisher)
    other_publisher = Factory(:publisher, :label => 'clickedin-sanantonio', :publishing_group => publishing_group)

    login_as consumer
    get :about_us, :publisher_id => other_publisher.id

    assert_equal(other_publisher.id, assigns(:publisher).id)
    assert_response :success
  end

  test "about us render publisher with enable redirect to local static page and membership master code" do
    publishing_group = Factory(:publishing_group, :label => "rr", :enable_redirect_to_local_static_pages => true)
    publisher = Factory(:publisher, :publishing_group => publishing_group)

    master_membership_code = Factory(:publisher_membership_code, :publisher => publisher, :master => true)

    consumer  = Factory(:consumer, :publisher => publisher)

    other_publisher = Factory(:publisher, :label => 'clickedin-sanantonio', :publishing_group => publishing_group)

    login_as consumer
    get :about_us, :publisher_id => other_publisher.id

    assert_equal(publisher.id, assigns(:publisher).id)
    assert_response :success
  end

  test "create with require_advertiser_revenue_share_percentage as true and no rev share passed" do
    publisher = Factory(:publisher, :require_advertiser_revenue_share_percentage => true)
    advertiser = Factory(:advertiser, :publisher => publisher)
    attributes = @valid_attributes.merge({:advertiser_revenue_share_percentage => ""})

    login_as Factory(:admin)

    post :create, :advertiser_id => advertiser.to_param, :daily_deal => attributes

    assert !assigns(:daily_deal).errors.empty?
  end

  context "GET to :official_rules, with a deal belonging to fundogo" do
    setup do
      @fundogo = Factory :publisher, :label => "fundogo"
      @advertiser = Factory :advertiser, :publisher => @fundogo
      @deal = Factory :daily_deal, :advertiser => @advertiser
    end
    
    should "return a 200 Ok" do
      get :official_rules, :id => @deal.to_param
      assert_response :success
    end
  end
end

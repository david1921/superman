require File.dirname(__FILE__) + "/../../test_helper"

class AdvertisersController::IndexTest < ActionController::TestCase
  tests AdvertisersController

  def setup
    @publisher = publishers(:sdh_austin)
  end

  def test_index
    check_result = lambda do |role|
      assert_response :success, "Should have success response as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"
      assert_equal @publisher.advertisers, assigns['advertisers'], "Assignment of @advertisers as #{role}"
      assert_select "form" do
        assert_select "input[type=submit][value=Delete]", 1
        assert_select "input[type=button][value='New Advertiser']", 1
      end
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      get :index, 'publisher_id' => @publisher.to_param
    end
  end
  
  def test_index_lacking_create_privilege
    @publisher.update_attributes! :can_create_advertisers => false

    check_result = lambda do |role|
      assert_response :success, "Should have success response as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"
      assert_equal @publisher.advertisers, assigns['advertisers'], "Assignment of @advertisers as #{role}"
      assert_select "form" do
        @publisher.advertisers.each do |advertiser|
          assert_select "tr#advertiser_#{advertiser.id}", 1 do
            assert_select "input[type=checkbox][name='id[]']", 1
            assert_select "input[type=checkbox][name='id[]'][disabled=disabled]", role =~ /admin/i ? 0 : 1
          end
        end
        assert_select "input[type=submit][value=Delete]", role =~ /admin/i ? 1 : 0
        assert_select "input[type=button][value='New Advertiser']", role =~ /admin/i ? 1 : 0
      end
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      get :index, 'publisher_id' => @publisher.to_param
    end
  end
  
  def test_index_with_txt_offers_enabled
    check_result = lambda do |role|
      assert_response :success, "Should have success response as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"
      assert_equal @publisher.advertisers, assigns['advertisers'], "Assignment of @advertisers as #{role}"
      assert_template 'index'
      assert_select "form" do
        @publisher.advertisers.each do |advertiser|
          assert_select "tr#advertiser_#{advertiser.id}", 1 do
            assert_select "td.total_coupons", 1
            assert_select "td.active_coupons", 1
            assert_select "td.total_txt_coupons", 1
            assert_select "td.active_txt_coupons", 1
            assert_select "a", :text => "Edit", :count => 1
            assert_select "a", :text => "New", :count => 3
          end
        end
        assert_select "input[type=submit][value=Delete]", 1
        assert_select "input[type=button][value='New Advertiser']", 1
      end
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      get :index, 'publisher_id' => @publisher.to_param
    end
  end
  
  def test_index_with_txt_offers_disabled
    @publisher.update_attributes! :txt_keyword_prefix => nil, :allow_offers => true
    
    check_result = lambda do |role|
      assert_response :success, "Should have success response as #{role}"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher as #{role}"
      assert_equal @publisher.advertisers, assigns['advertisers'], "Assignment of @advertisers as #{role}"
      assert_template :index
      assert_select "form" do
        @publisher.advertisers.each do |advertiser|
          assert_select "tr#advertiser_#{advertiser.id}", 1 do
            assert_select "td.total_coupons", 1
            assert_select "td.active_coupons", 1
            assert_select "td.total_txt_coupons", 0
            assert_select "td.active_txt_coupons", 0
            assert_select "a", :text => "Edit", :count => 1
            assert_select "a", :text => "New", :count => 2
          end
        end
        assert_select "input[type=submit][value=Delete]", 1
        assert_select "input[type=button][value='New Advertiser']", 1
      end
    end
    with_login_managing_publisher_required(@publisher, check_result) do
      get :index, 'publisher_id' => @publisher.to_param
    end
  end
  
  def test_index_as_demo_user
    demo_user = create_demo_user!
    get :index, 'publisher_id' => publishers(:my_space).to_param
    assert_response :success
    assert_equal @request.session[:user_id],  demo_user.id, "Should login as demo user"
    assert_select "a", :text => "Edit", :count => 0
    assert_select "a", :text => "New", :count => 0
    assert_select "input[type=submit][value=Delete]", 0
    assert_select "input[type=button][value='New Advertiser']", 0
  end

  def test_index_page_offers_counts
    @publisher.update_attributes! :self_serve => true
    
    advertiser_1 = @publisher.advertisers.create!(:name => "Advertiser 1")
    advertiser_1.offers.create! :message => "A1 O1", :show_on => "Nov 01, 2008", :expires_on => "Nov 30, 2008"
    advertiser_1.offers.create! :message => "A1 O2", :show_on => "Nov 15, 2008", :expires_on => "Nov 30, 2008"

    advertiser_2 = @publisher.advertisers.create!(:name => "Advertiser 2")
    advertiser_2.offers.create! :message => "A2 O1", :expires_on => "Nov 30, 2008"
    advertiser_2.offers.create! :message => "A2 O2", :expires_on => "Nov 30, 2008", :deleted_at => Time.now
    
    Timecop.freeze Date.new(2008, 11, 2) do
      with_user_required(:mickey) do
        get :index, 'publisher_id' => @publisher.to_param
      end
      assert_response :success, "Should have success response"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher"
      assert_equal Advertiser.search(:publisher => @publisher), assigns['advertisers'], "Assignment of @advertisers"
      assert_select "form" do
        assert_select "tr.advertiser", 4
        assert_select "tr#advertiser_#{advertiser_1.id}", 1 do
          assert_select "td.name", "Advertiser 1", 1
          assert_select "td.total_coupons", "2"
          #      assert_select "td.active_coupons", "" # xxx  this fails like 30% of the time
        end
        assert_select "tr#advertiser_#{advertiser_2.id}", 1 do
          assert_select "td.name", "Advertiser 2", 1
          assert_select "td.total_coupons", "1"
          assert_select "td.active_coupons", "1"
        end
      end
    end
  end

  def test_index_page_txt_offers_counts
    @publisher.update_attributes! :self_serve => true, :txt_keyword_prefix => "SDH"
    
    advertiser_1 = @publisher.advertisers.create!(:name => "Advertiser 1")
    advertiser_1.txt_offers.create! :keyword => "SDHA1T1", :message => "A1 T1", :appears_on => "Nov 01, 2008", :expires_on => "Nov 30, 2008"
    advertiser_1.txt_offers.create! :keyword => "SDHA1T2", :message => "A1 T2", :appears_on => "Nov 15, 2008", :expires_on => "Nov 30, 2008"

    advertiser_2 = @publisher.advertisers.create!(:name => "Advertiser 2")
    advertiser_2.txt_offers.create! :keyword => "SDHA2T1", :message => "A2 T1", :expires_on => "Nov 30, 2008"
    advertiser_2.txt_offers.create! :keyword => "SDHA2T2", :message => "A2 T2", :expires_on => "Nov 30, 2008", :deleted => true
    
    Timecop.freeze Date.new(2008, 11, 2) do
      login_as :mickey
      get :index, 'publisher_id' => @publisher.to_param
      assert_response :success, "Should have success response"
      assert_equal @publisher, assigns['publisher'], "Assignment of @publisher"
      assert_equal Advertiser.search(:publisher => @publisher), assigns['advertisers'], "Assignment of @advertisers"
      assert_select "form" do
        assert_select "tr.advertiser", 4
        assert_select "tr#advertiser_#{advertiser_1.id}" do
          assert_select "td.name", "Advertiser 1"
          assert_select "td.total_txt_coupons", :text => "2"
          #       assert_select "td.active_txt_coupons", "" #xxx this fails like 30% of the time
        end
        assert_select "tr#advertiser_#{advertiser_2.id}", 1 do
          assert_select "td.name", "Advertiser 2", 1
          assert_select "td.total_txt_coupons", "1"
          assert_select "td.active_txt_coupons", "1"
        end
      end
    end
  end
  
  def test_index_with_deleted_advertiser
    publisher           = Factory(:publisher)
    active_advertiser   = Factory(:advertiser, :name => "I am active", :publisher => publisher)
    deleted_advertiser  = Factory(:advertiser, :name => "I am deleted", :publisher => publisher, :deleted_at => 2.days.ago) 
    
    login_as( Factory(:admin) )
    
    get :index, :publisher_id => publisher.to_param
    
    assert_response :success     
#    assert_equal [active_advertiser], assigns(:advertisers)
  end

  def test_index_without_offers
    publisher = Factory(:publisher, :allow_offers => false)
    publisher.stubs(:uses_coupons?)
    advertiser = Factory(:advertiser, :publisher => publisher)
    login_as :aaron
    get :index, :publisher_id => publisher.to_param
    assert_response :ok
    assert_template 'index'
    assert_select 'th.total_coupons', 0
    assert_select 'th.active_coupons', 0
    assert_select "tr#advertiser_#{advertiser.id}" do
      assert_select 'td.total_coupons', 0
      assert_select 'td.active_coupons', 0
    end
  end

  context "can manage consumers" do

    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @user      = Factory(:user, :company => @publisher)
    end

    should "display view all consumer link for a user who can manage consumers" do
      @user.update_attribute(:can_manage_consumers, true)
      login_as @user
      get :index, :publisher_id => @publisher.to_param
      assert_response :success
      assert_select "a[href='#{publisher_consumers_path(@publisher.to_param)}']", :text => "View All Consumers"
    end

    should "NOT display view all consumer link for a user who can not manage consumers" do
      @user.update_attribute(:can_manage_consumers, false)
      login_as @user
      get :index, :publisher_id => @publisher.to_param
      assert_response :success
      assert_select "a[href='#{publisher_consumers_path(@publisher.to_param)}']", false
    end

  end
end

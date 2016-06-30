require File.dirname(__FILE__) + "/../test_helper"

class DiscountsControllerTest < ActionController::TestCase
  test "new" do
    publisher = Factory(:publisher)
    
    login_as(:aaron)
    get :new, :publisher_id => publisher.to_param
    
    assert_response :success
    assert_template :edit
    assert_equal publisher, assigns(:publisher)
    assert_not_nil(discount = assigns(:discount))
  end

  test "create" do
    publisher = Factory(:publisher)
    
    login_as(:aaron)
    assert_difference 'publisher.discounts.count' do
      post :create, :publisher_id => publisher.to_param, :discount => {
        :code => "NEWDEAL20",
        :amount => "20",
        :first_usable_at => "August 01, 2010 12:00 AM",
        :last_usable_at => "August 31, 2010 11:55 PM",
        :usable_at_checkout => "1"
      }
    end
    assert_redirected_to edit_publisher_path(publisher)
    
    discount = publisher.discounts.first
    assert_equal "NEWDEAL20", discount.code
    assert_equal 20.00, discount.amount
    assert_equal Time.zone.parse("Aug 01, 2010 00:00:00"), discount.first_usable_at
    assert_equal Time.zone.parse("Aug 31, 2010 23:55:00"), discount.last_usable_at
    assert discount.usable_at_checkout, "Discount should be usable at checkout"
    assert !discount.usable_only_once?, "Discount should, by default, not be a single use discount"
  end

  test "create with single use discount" do
    publisher = Factory(:publisher)

    login_as(:aaron)
    assert_difference 'publisher.discounts.count' do
      post :create, :publisher_id => publisher.to_param, :discount => {
        :code => "NEWDEAL20",
        :amount => "20",
        :first_usable_at => "August 01, 2010 12:00 AM",
        :last_usable_at => "August 31, 2010 11:55 PM",
        :usable_at_checkout => "1",
        :usable_only_once => "1"
      }
    end
    assert_redirected_to edit_publisher_path(publisher)
    discount = publisher.discounts.first
    assert discount.usable_only_once?, "Discount should, by default, not be a single use discount"
  end

  test "edit" do
    discount = Factory(:discount)
    
    login_as(:aaron)
    get :edit, :publisher_id => discount.publisher.to_param, :id => discount.to_param
    assert_response :success
    assert_template :edit
    assert_equal discount.publisher, assigns(:publisher)
    assert_equal discount, assigns(:discount)
    
    assert_select "form[action=#{publisher_discount_path(discount.publisher, discount)}]", 1 do
      assert_select "input[type=text][name='discount[code]'][value=#{discount.code}]", 1
      assert_select "input[type=text][name='discount[amount]']", 1
      assert_select "input[type=text][name='discount[first_usable_at]']", 1
      assert_select "input[type=text][name='discount[last_usable_at]']", 1
      assert_select "input[type=checkbox][name='discount[usable_at_checkout]']", 1
      assert_select "input[type=checkbox][name='discount[usable_only_once]']", 1
    end
  end
  
  test "update" do
    discount = Factory(:discount)
    publisher = discount.publisher

    login_as(:aaron)
    assert_no_difference 'publisher.discounts.count' do
      put :update, :publisher_id => publisher.to_param, :id => discount.to_param, :discount => {
        :code => "NEWDEAL20",
        :amount => "20",
        :first_usable_at => "August 01, 2010 12:00 AM",
        :last_usable_at => "August 31, 2010 11:55 PM",
        :usable_at_checkout => "1"
      }
    end
    assert_redirected_to edit_publisher_path(publisher)
    
    discount = publisher.discounts.first
    assert_equal "NEWDEAL20", discount.code
    assert_equal 20.00, discount.amount
    assert_equal Time.zone.parse("Aug 01, 2010 00:00:00"), discount.first_usable_at
    assert_equal Time.zone.parse("Aug 31, 2010 23:55:00"), discount.last_usable_at
    assert discount.usable_at_checkout, "Discount should be usable at checkout"
  end
  
  test "destroy" do
    discount = Factory(:discount)
    publisher = discount.publisher
    
    login_as(:aaron)
    assert_no_difference 'publisher.discounts.count' do
      delete :destroy, :publisher_id => publisher.to_param, :id => discount.to_param
    end
    assert_redirected_to edit_publisher_path(publisher)
    
    assert discount.reload.deleted?, "Discount should be marked deleted"
  end

  test "index" do
    discount = Factory(:discount)
    publisher = discount.publisher
    login_as(:aaron)
    get :index, :publisher_id => publisher.to_param
    assert_response :success
    assert_template :index
    assert assigns(:paginate_params)
  end

  test "index with code search" do
    discount = Factory(:discount, :code => "MYFUNCODE")
    publisher = discount.publisher
    Factory(:discount, :publisher => discount.publisher, :code => "MYFUNCODE2")
    login_as(:aaron)
    get :index, :publisher_id => publisher.to_param, :search => {
      :code => discount.code
    }
    assert_response :success
    assert_select "#discount_codes tr", 2
    assert_select "#discount_codes tr:nth-child(2)" do
      assert_select "td", :text => "MYFUNCODE"
    end
  end

  test "index with invalid code search" do
    discount = Factory(:discount, :code => "HAPPYCODE")
    publisher = discount.publisher
    login_as(:aaron)
    get :index, :publisher_id => publisher.to_param, :search => {
      :code => "WRONGCODE"
    }
    assert_response :success
    assert_select "#discount_codes tr", 1
  end

  test "apply" do
    discount  = Factory(:discount)
    publisher = discount.publisher

    xhr :post, :apply, :publisher_id => publisher.id, :daily_deal_purchase => {
      :discount_code => discount.code
    }

    assert_response :success
    assert assigns(:publisher), "Assign @publisher"
    assert assigns(:discount), "Assign @discount"
  end

  test "apply with a not usable discount" do
    discount  = Factory(:discount, :used_at => Time.now)
    publisher = discount.publisher

    xhr :post, :apply, :publisher_id => publisher.id, :daily_deal_purchase => {
      :discount_code => discount.code
    }

    assert_response :success
    assert assigns(:publisher), "Assign @publisher"
    assert !assigns(:discount), "Do not assign @discount"
  end

  context "#create" do
    should "render edit on failure" do
      publisher = Factory(:publisher)
      login_as(:aaron)
      post :create, :publisher_id => publisher.to_param, :discount => {}
      assert_response :ok
      assert_template :edit
    end
  end

end

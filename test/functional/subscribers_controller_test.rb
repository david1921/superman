require File.dirname(__FILE__) + "/../test_helper"

class SubscribersControllerTest < ActionController::TestCase
  def test_new
    get :new, :publisher_id => publishers(:my_space).to_param
    assert_response :success
    assert_layout "subscribers/public_index"
    assert_not_nil assigns(:subscriber), "@subscriber"
    assert_template "subscribers/new"
    
    assert_select "div#new_subscriber" do
      assert_select "h3", :html => "Discounts &amp; Coupons<br />In Your Inbox or to Your Phone"
      assert_select "form" do
        assert_select "input[type=text][name='subscriber[email]']"
        assert_select "input[type=text][name='subscriber[mobile_number]']"
        assert_select "input[type=text][name='subscriber[other_options][zip_code]']", false
        assert_select "select[name='subscriber[other_options][distance]']", false
        assert_select "input[type=checkbox][name='everything']"
      end
    end
  end
  
  def test_new_with_nydailynews_publisher
    publisher = Factory(:publisher, :label => "nydailynews")
    get :new, :publisher_id => publisher.to_param
    assert_response :success
    assert_layout   "subscribers/public_index"
    assert_template "subscribers/nydailynews/new"
  end

  def test_create_thomsonlocal
    publisher = Factory(:publisher_with_uk_address, :label => "thomsonlocal", :countries => [Country.find_by_code('uk')])
    @request.env["HTTP_REFERER"] = presignup_publisher_consumers_path(publisher)
    post :create, :publisher_id => publisher.label,
      :redirect_to => verifiable_url(presignup_publisher_consumers_path(publisher)),
      :subscriber  => {
        :email             => "test@example.com",
        :first_name        => "Foo",
        :last_name         => "Baz",
        :zip_code          => "EC1A 1BB",
        :terms             => "1",
        :email_required    => true,
        :zip_code_required => true,
        :must_accept_terms => true
      }

    subscriber = assigns(:subscriber)
    assert subscriber.errors.empty?, subscriber.errors.full_messages.join(", ")
    assert_redirected_to presignup_publisher_consumers_path(publisher)
    subscriber = publisher.subscribers.first 
    assert_equal subscriber.zip_code, "EC1A 1BB"
  end
  
  def test_create
    assert_equal 0, Subscriber.count, "subscribers"
    xhr :post, :create, :publisher_id => publishers(:my_space).to_param, :subscriber => { :email => "tom@example.com", :first_name => "Bob", :last_name => "Jones", :mobile_number => "1234567890" }
    assert_not_nil assigns(:subscriber), "@subscriber"
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert assigns(:subscriber).errors.empty?, assigns(:subscriber).errors.full_messages.join(". ")
    assert_response :success
    assert_not_nil flash[:notice]
    assert_equal 1, Subscriber.count, "subscribers"
    subscriber = Subscriber.first
    assert_equal 0, subscriber.categories.count, "Subscriber categories"
    assert_equal "Bob Jones", subscriber.name, "Subscriber name"
    assert_nil subscriber.other_options
    assert_equal "subscribed", cookies["subscribed"], "subscribed cookie"
  end
  
  def test_create_html
    assert_equal 0, Subscriber.count, "subscribers"
    post :create, :publisher_id => publishers(:my_space).to_param, :subscriber => { :email => "tom@example.com", :mobile_number => "1234567890" }
    assert_not_nil assigns(:subscriber), "@subscriber"
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert assigns(:subscriber).errors.empty?, assigns(:subscriber).errors.full_messages.join(". ")
    assert_redirected_to publisher_home_path(:label => publishers(:my_space).label)
    assert_not_nil flash[:notice]
    assert_equal 1, Subscriber.count, "subscribers"
    subscriber = Subscriber.first
    assert_equal 0, subscriber.categories.count, "Subscriber categories"
    assert_nil subscriber.other_options
    assert_equal "subscribed", cookies["subscribed"], "subscribed cookie"
  end
  
  def test_create_with_categories
    assert_equal 0, Subscriber.count, "subscribers"
    xhr :post, 
        :create, 
        :publisher_id => publishers(:my_space).to_param, 
        :category_id => [ categories(:household).to_param, categories(:restaurants).to_param ],
        :subscriber => { :email => "tom@example.com", :mobile_number => "1234567890" }
    assert_not_nil assigns(:subscriber), "@subscriber"
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert assigns(:subscriber).errors.empty?, assigns(:subscriber).errors.full_messages.join(". ")
    assert_response :success
    assert_not_nil flash[:notice]
    assert_equal 1, Subscriber.count, "subscribers"
    subscriber = Subscriber.first
    assert_equal 2, subscriber.categories.count, "Subscriber categories"
    assert_equal [ categories(:household), categories(:restaurants) ].sort_by(&:name), subscriber.categories.sort_by(&:name), "Subscriber categories"
    assert_nil subscriber.other_options
  end

  def test_create_with_other_options
    assert_equal 0, Subscriber.count, "subscribers"
    xhr :post, 
        :create, 
        :publisher_id => publishers(:sdreader).to_param, 
        :category_id => [ categories(:household).to_param, categories(:restaurants).to_param ],
        :subscriber => { :email => "tom@example.com", :mobile_number => "1234567890", :other_options => ["more", "spam"] }
    assert_not_nil assigns(:subscriber), "@subscriber"
    assert_equal publishers(:sdreader), assigns(:publisher), "@publisher"
    assert assigns(:subscriber).errors.empty?, assigns(:subscriber).errors.full_messages.join(". ")
    assert_response :success
    assert_not_nil flash[:notice]
    assert_equal 1, Subscriber.count, "subscribers"
    subscriber = Subscriber.first
    assert_equal 2, subscriber.categories.count, "Subscriber categories"
    assert_equal [ categories(:household), categories(:restaurants) ].sort_by(&:name), subscriber.categories.sort_by(&:name), "Subscriber categories"
    assert_equal ["more", "spam"], subscriber.other_options
  end
  
  def test_create_with_other_options_being_zip_code_and_distance
    assert_equal 0, Subscriber.count, "subscribers"
    other_options = {"zip_code" => "97206", "distance" => "10"}
    xhr :post, 
        :create, 
        :publisher_id => publishers(:sdreader).to_param, 
        :category_id => [ categories(:household).to_param, categories(:restaurants).to_param ],
        :subscriber => { :email => "tom@example.com", :mobile_number => "1234567890", :other_options => other_options }
    assert_not_nil assigns(:subscriber), "@subscriber"
    assert_equal publishers(:sdreader), assigns(:publisher), "@publisher"
    assert assigns(:subscriber).errors.empty?, assigns(:subscriber).errors.full_messages.join(". ")
    assert_response :success
    assert_not_nil flash[:notice]
    assert_equal 1, Subscriber.count, "subscribers"
    subscriber = Subscriber.first
    assert_equal 2, subscriber.categories.count, "Subscriber categories"
    assert_equal [ categories(:household), categories(:restaurants) ].sort_by(&:name), subscriber.categories.sort_by(&:name), "Subscriber categories"
    assert_equal other_options, subscriber.other_options        
  end 
  
  def test_create_with_subscriber_referrer_code_id
    assert_equal 0, Subscriber.count, "subscribers"
    subscriber_referrer_code = SubscriberReferrerCode.create!
    post :create, :publisher_id => publishers(:my_space).to_param, 
         :subscriber => { 
          :email => "tom@example.com", 
          :mobile_number => "1234567890", 
          :subscriber_referrer_code_id => subscriber_referrer_code.id 
    }
    assert_not_nil assigns(:subscriber)
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert assigns(:subscriber).errors.empty?
    assert_equal subscriber_referrer_code, assigns(:subscriber).subscriber_referrer_code
  end
  
  def test_create_with_device_and_user_agent
    assert_equal 0, Subscriber.count, "subscribers"
    @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)"
    post :create, :publisher_id => publishers(:my_space).to_param, :subscriber => { :email => "tom@example.com", :mobile_number => "1234567890", :device => "mobile" }
    
    subscriber = assigns(:subscriber)
    assert_equal "mobile", subscriber.device
    assert_equal "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)", subscriber.user_agent    
  end
  
  def test_invalid_create
    assert_equal 0, Subscriber.count, "subscribers"
    xhr :post, :create, :publisher_id => publishers(:my_space).to_param, :subscriber => { :email => "", :mobile_number => "" }
    assert_not_nil assigns(:subscriber), "@subscriber"
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert assigns(:subscriber).errors.any?, "@subscriber should have errors"
    assert_response :success
    assert_equal 0, Subscriber.count, "subscribers"
    assert_equal nil, cookies[:subscribed], "subscribed cookie"
  end
  
  def test_upload_without_admin_account
    publisher = Factory(:publisher)
    user      = Factory(:user, :company => publisher)
    login_as user
    get :upload, :publisher_id => publisher.id
    assert_redirected_to root_path
  end
  
  def test_upload_with_admin_account
    publisher = Factory(:publisher)
    login_as Factory(:admin)
    get :upload, :publisher_id => publisher.id
    assert_response :success
    assert_template "subscribers/upload"
    assert_layout "application"
    assert_equal publisher, assigns(:publisher), "should look up the correct publisher"
    
    assert_select "form[method='post'][action='#{upload_publisher_subscribers_path(publisher.id)}']" do
      assert_select "textarea[name='subscriber[email_addresses]']"
    end
  end
  
  def test_post_upload_with_admin_account_and_no_email_addresses
    publisher = Factory(:publisher)
    login_as Factory(:admin)
    post :upload, :publisher_id => publisher.id, :subscriber => {:email_addresses => ""}
    assert_response :success
    assert_select "div.message", :html => "<strong>Warning:</strong> No email addresses were found, please supply a list of email addresses."
  end
  
  def test_post_upload_with_admin_account_and_new_email_addresses
    publisher = Factory(:publisher)
    login_as Factory(:admin)
    post :upload, :publisher_id => publisher.id, :subscriber => {:email_addresses => "jim.smith@somewhere.com\r\njill.smart@smart.com"}
    assert_response :success
    assert_equal 2, assigns(:new_entries).size
    assert_equal 2, publisher.reload.subscribers.size
  end
  
  def test_post_upload_with_admin_account_with_existing_email_address
    publisher = Factory(:publisher)
    subscriber = Factory(:subscriber, :publisher => publisher)
    login_as Factory(:admin)
    post :upload, :publisher_id => publisher.id, :subscriber => {:email_addresses => "#{subscriber.email}\r\njill.smart@smart.com"}
    assert_response :success
    assert_equal 1, assigns(:new_entries).size
    assert_equal 1, assigns(:already_exists).size
    assert_equal 2, publisher.reload.subscribers.size    
  end
  
  def test_post_upload_with_admin_account_and_invalid_email_address
    publisher = Factory(:publisher)
    login_as Factory(:admin)
    post :upload, :publisher_id => publisher.id, :subscriber => {:email_addresses => "blah\r\nnothing"}
    assert_response :success
    assert_equal 2, assigns(:invalid_entries).size
    assert_equal 0, publisher.reload.subscribers.size    
  end
  
end

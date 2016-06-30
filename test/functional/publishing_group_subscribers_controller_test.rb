require File.dirname(__FILE__) + "/../test_helper"

class PublishingGroupSubscribersControllerTest < ActionController::TestCase
  test "create without redirect_to parameter" do
    publishing_group = Factory(:publishing_group, :label => "moxtelecom")
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    
    assert_difference 'publisher.subscribers.count' do
      post :create, :publishing_group_id => publishing_group.label, :publisher_label => publisher.label, :subscriber => { :email => "john@public.com" }
    end
    assert_redirected_to thank_you_publishing_group_subscribers_path(publishing_group.label)
    
    subscriber = publisher.subscribers.last
    assert_equal "john@public.com", subscriber.email
  end

  test "create with redirect_to parameter" do
    publishing_group = Factory(:publishing_group, :label => "moxtelecom")
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    
    assert_difference 'publisher.subscribers.count' do
      post :create, {
        :publishing_group_id => publishing_group.label,
        :redirect_to => verifiable_url(subscribed_publisher_daily_deals_path(publisher)),
        :publisher_label => publisher.label,
        :subscriber => { :email => "john@public.com" }
      }
    end
    assert_redirected_to subscribed_publisher_daily_deals_path(publisher)
    
    subscriber = publisher.subscribers.last
    assert_equal "john@public.com", subscriber.email
  end 
  
  test "create with empty publisher label" do
    publishing_group = Factory(:publishing_group, :label => "moxtelecom")
    
    @request.env['HTTP_REFERER'] = 'http://localhost:3000/publishing_groups/villagevoicemedia/landing_page'
    
    post :create, {
      :publishing_group_id => publishing_group.label,
      :publisher_label => ""
    }
    
    assert_redirected_to('http://localhost:3000/publishing_groups/villagevoicemedia/landing_page')
  end 
  
  test "create with device and user_agent" do
    publishing_group = Factory(:publishing_group, :label => "moxtelecom")
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    
    @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)"
    assert_difference 'publisher.subscribers.count' do
      post :create, :publishing_group_id => publishing_group.label, :publisher_label => publisher.label, :subscriber => { :email => "john@public.com", :device => "mobile" }
    end
    assert_redirected_to thank_you_publishing_group_subscribers_path(publishing_group.label)
    
    subscriber = publisher.subscribers.last
    assert_equal "john@public.com", subscriber.email
    assert_equal "mobile", subscriber.device
    assert_equal "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)", subscriber.user_agent
  end

  test "create with no publisher label and valid publishing group label" do
    publishing_group = Factory(:publishing_group, :label => "rr")
    
    @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(publishing_group.label, :host => "test.host")
    
    post :create, {
      :publishing_group_id => publishing_group.label,
      :subscriber => { :email => "john@public.com", :name => "John Smith", :zip_code => "99999" },
      :redirect_to => verifiable_url(search_publishing_group_markets_path(publishing_group.label))
    }
            
    assert_equal 1, publishing_group.subscribers_with_no_market.size
    assert_redirected_to search_publishing_group_markets_path(publishing_group.label)
  end
  
  test "thank_you" do
    publishing_group = Factory(:publishing_group, :label => "foo")

    assert_no_difference 'Subscriber.count' do
      get :thank_you, :publishing_group_id => publishing_group.label
    end
    assert_response :success
    
    assert @controller.analytics_tag.signup?
  end

  test "create should accept publisher_id to determine the publisher" do
    publishing_group = Factory(:publishing_group, :label => "locm")
    publisher = Factory(:publisher, :publishing_group => publishing_group)

    assert_difference 'publisher.subscribers.count' do
      post :create, {
        :publishing_group_id => publishing_group.label,
        :publisher_id => publisher.id,
        :subscriber => { :email => "john@public.com", :name => "John Smith", :zip_code => "99999" },
      }
    end

    assert_redirected_to( thank_you_publishing_group_subscribers_url(publishing_group.label) )
  end

  test "create should redirect to the publishers deal page if redirect_to_deal_page is set" do
    publishing_group = Factory(:publishing_group, :label => "locm")
    publisher = Factory(:publisher, :publishing_group => publishing_group)

    Timecop.freeze do # cookie expiry is in seconds, comparison could fail
      assert_difference 'publisher.subscribers.count' do
        post :create, {
          :publishing_group_id => publishing_group.label,
          :publisher_id => publisher.id,
          :subscriber => { :email => "john@public.com", :email_required => true, :name => "John Smith", :zip_code => "99999" },
          :redirect_to_deal_page => true
        }
      end

      assert_redirected_to( public_deal_of_day_url(publisher.label) )
      assert_equal publisher.label, @response.cookies['publisher_label'], "publisher label cookie"
      assert_equal 10.years.from_now.to_i, better_cookies['publisher_label']['expires'].to_i
    end
  end

  test "create should not set publisher label cookie unless successful" do
    publishing_group = Factory(:publishing_group, :label => "locm")
    publisher = Factory(:publisher, :publishing_group => publishing_group)

    @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(publishing_group.label, :host => "test.host")

    assert_no_difference 'publisher.subscribers.count' do
      post :create, {
        :publishing_group_id => publishing_group.label,
        :publisher_id => publisher.id,
        :subscriber => { :email => "", :email_required => true },
      }
    end

    assert_response :redirect
    assert_nil @response.cookies['publisher_label'], "publisher label cookie"
  end

  test "create should require publisher if redirect_to_deal_page is set" do
    publishing_group = Factory(:publishing_group, :label => "locm")

    @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(publishing_group.label, :host => "test.host")

    assert_no_difference 'Subscriber.count' do
      post :create, {
        :publishing_group_id => publishing_group.label,
        :subscriber => { :email => "john@public.com", :name => "John Smith", :zip_code => "99999" },
        :redirect_to_deal_page => true
      }
    end

    assert_redirected_to @request.env["HTTP_REFERER"]
  end

  context "find publisher by zip code" do
    setup do
      @publishing_group = Factory(:publishing_group, :label => "entertainment")

      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @publisher_zip_code = Factory(:publisher_zip_code, :zip_code => "98685", :publisher => @publisher)

      @publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
      Factory(:publisher_zip_code, :zip_code => "97214", :publisher => @publisher2)
      Factory(:publisher_zip_code, :zip_code => "08504", :publisher => @publisher2)
      Factory(:publisher, :label => "entertainment", :publishing_group => @publishing_group)
    end

    should "create a subscriber on zip code's publisher" do
      assert_difference '@publisher.subscribers.count', 1 do
        post :create, {
          :publishing_group_id => @publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "John Smith", :zip_code => "98685" },
          :redirect_to_deal_page => true,
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end

      assert_redirected_to public_deal_of_day_url(@publisher.label)
    end

    should "create a subscriber on zip code's publisher when subscriber's zipcode is in the larger zipcode format" do

       publishing_group = Factory(:publishing_group, :label => "locm")
       @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(publishing_group.label, :host => "test.host")

      assert_difference "@publisher.subscribers.count", 1 do
        post :create, {
          :publishing_group_id =>  @publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "Joe Smith", :zip_code => "98685-1234"},
          :redirect_to_deal_page => true,
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end

      assert_redirected_to public_deal_of_day_url(@publisher.label)
    end

    should "create a subscriber on zip code's publisher when subscriber's zipcode has leading zero" do
       publishing_group = Factory(:publishing_group, :label => "locm")
       @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(publishing_group.label, :host => "test.host")

      assert_difference "@publisher2.subscribers.count", 1 do
        post :create, {
          :publishing_group_id =>  @publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "Joe Smith", :zip_code => "08504"},
          :redirect_to_deal_page => true,
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end

      assert_redirected_to public_deal_of_day_url(@publisher2.label)
      assert_equal "08504", assigns(:subscriber).zip_code
      assert_equal @publisher2.id, assigns(:subscriber).publisher_id
    end

    should "create a subscriber on zip code's publisher when subscriber's zipcode is long without the dash" do
       publishing_group = Factory(:publishing_group, :label => "locm")
       @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(publishing_group.label, :host => "test.host")

      assert_difference "@publisher2.subscribers.count", 1 do
        post :create, {
          :publishing_group_id =>  @publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "Joe Smith", :zip_code => "972141234"},
          :redirect_to_deal_page => true,
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end

      assert_redirected_to public_deal_of_day_url(@publisher2.label)
      assert_equal "972141234", assigns(:subscriber).zip_code
      assert_equal @publisher2.id, assigns(:subscriber).publisher_id
    end

    should "create a subscriber on zip code's publisher when subscriber's zipcode has four digits and a dash" do
       publishing_group = Factory(:publishing_group, :label => "locm")
       @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(publishing_group.label, :host => "test.host")

      assert_difference "@publisher2.subscribers.count", 1 do
        post :create, {
          :publishing_group_id =>  @publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "Joe Smith", :zip_code => "97214-"},
          :redirect_to_deal_page => true,
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end

      assert_redirected_to public_deal_of_day_url(@publisher2.label)
      assert_equal "97214-", assigns(:subscriber).zip_code
      assert_equal @publisher2.id, assigns(:subscriber).publisher_id
    end

    should "set warning when a publisher is not found for a given zip code and redirect back" do
      @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(@publishing_group.label, :host => "test.host")
      assert_no_difference "Subscriber.count" do
        post :create, {
          :publishing_group_id => @publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "John Smith", :zip_code => "999" },
          :redirect_to_deal_page => true,
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end
      assert_redirected_to :back
      assert_equal "'999' is not a valid zip code", flash[:warn]
    end

    should "set a warning when a publisher is not found for a given zip code, add the subscriber to " +
           "the #default_publisher_for_subscribers, and redirect back" do
      assert_equal "entertainment", @publishing_group.default_publisher_for_subscribers.label
      @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(@publishing_group.label, :host => "test.host")

      assert_difference 'Subscriber.count', 1 do
        post :create, {
          :publishing_group_id => @publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "John Smith", :zip_code => "99999" },
          :redirect_to_deal_page => true,
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end
      
      subscriber = assigns(:subscriber)
      assert_instance_of Subscriber, subscriber
      assert_equal "entertainment", subscriber.publisher.label
      assert_equal "john@public.com", subscriber.email
      assert_equal "99999", subscriber.zip_code

      assert_equal "Zip code entered was invalid or not available in a current market.", flash[:warn]
      assert_redirected_to @request.env["HTTP_REFERER"]
    end

    should "set a warning when a publisher is not found for a given zip code and redirect back, and " +
           "not create a subscriber when #default_publisher_for_subscribers is nil" do
      publishing_group = Factory :publishing_group, :label => "freedom"
      Factory :publisher, :publishing_group => publishing_group
      assert_nil publishing_group.default_publisher_for_subscribers
      @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(publishing_group.label, :host => "test.host")

      assert_no_difference 'Subscriber.count' do
        post :create, {
          :publishing_group_id => publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "John Smith", :zip_code => "99999" },
          :redirect_to_deal_page => true,
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end
      
      assert_equal "Zip code entered was invalid or not available in a current market.", flash[:warn]
      assert_redirected_to @request.env["HTTP_REFERER"]
    end

    should "set warning when no zip code is given and redirect back" do
      @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(@publishing_group.label, :host => "test.host")

      assert_no_difference 'Subscriber.count' do
        post :create, {
          :publishing_group_id => @publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "John Smith" },
          :redirect_to_deal_page => true,
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end

      assert_equal "Please enter a zip code.", flash[:warn]
      assert_redirected_to @request.env["HTTP_REFERER"]
    end

    should "redirect to :failure_redirect_to if present after failing to find publisher for zip" do
      assert_difference 'Subscriber.count', 1 do
        post :create, {
          :publishing_group_id => @publishing_group.label,
          :subscriber => { :email => "john@public.com", :name => "John Smith", :zip_code => "99999" },
          :redirect_to_deal_page => true,
          :publisher_not_found_redirect_to => verifiable_url("http://example.com"),
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end

      assert_redirected_to "http://example.com"
    end

    should "not redirect to :failure_redirect_to if zip code not given" do
      @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(@publishing_group.label, :host => "test.host")

      assert_no_difference 'Subscriber.count' do
        post :create, {
          :publishing_group_id => @publishing_group.label,
          :subscriber => { :email => "john", :name => "John Smith", :zip_code => "" },
          :redirect_to_deal_page => true,
          :publisher_not_found_redirect_to => "http://example.com",
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end

      assert_redirected_to @request.env["HTTP_REFERER"]
    end

    should "not redirect to :failure_redirect_to due to subscriber validation errors" do
      @request.env["HTTP_REFERER"] = publishing_group_subscribers_url(@publishing_group.label, :host => "test.host")

      assert_no_difference 'Subscriber.count' do
        post :create, {
          :publishing_group_id => @publishing_group.label,
          :subscriber => { :email => "john", :name => "John Smith", :zip_code => "98685" },
          :redirect_to_deal_page => true,
          :publisher_not_found_redirect_to => "http://example.com",
          :assign_subscriber_to_publisher_by_zip_code => true
        }
      end

      assert_redirected_to @request.env["HTTP_REFERER"]
    end

  end
end

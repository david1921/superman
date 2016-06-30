require File.dirname(__FILE__) + "/../../test_helper"

class Reports::CouponsControllerTest < ActionController::TestCase
  def setup
    TxtOffer.clear_cache
    @advertiser = advertisers(:changos)
    @publisher = @advertiser.publisher
    assert @advertiser.offers.any?, "Should have some offer fixtures for this advertiser"
  end

  test "should redirect if not on reports.analoganalytics.com in production mode" do
    stub_host_as_admin_server
    get :index
    assert_response :redirect
    assert_match /^https?:\/\/reports\.analoganalytics\.com/, @response.headers['Location']
  end

  test "should not redirect if on reports.analoganalytics.com in production mode" do
    stub_host_as_reports_server
    login_as Factory(:admin)
    get :index, :advertiser_id => Factory(:advertiser)
    assert_response :success
  end

  def test_get_index_as_admin_user
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    get_index_with_default_or_given_dates(users(:aaron), time, dates) do |action, mode, dates|
      action.call
      assert_response :success, "HTTP response code for #{mode}"
      assert_equal @advertiser, assigns(:advertiser), "@advertiser assignment for #{mode}"
      assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
    end
  end

  def test_xhr_index_as_admin_user
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    xhr_index_with_default_or_given_dates(users(:aaron), time, dates) do |action, mode, dates|
      action.call
      assert_response :success, "HTTP response code for #{mode}"
      assert_equal @advertiser, assigns(:advertiser), "@advertiser assignment for #{mode}"
      assert_equal @advertiser.offers, assigns(:offers), "@offers assignment for #{mode}"
      assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
    end
  end

  def test_get_index_as_owning_publishing_group_user
    group = @publisher.publishing_group
    assert_not_nil group, "Publisher fixture should belong to a publishing group"
    user = User.all.detect { |user| group == user.company }
    assert_not_nil user, "Publishing group should have a user"
    
    2.times { |i| @publisher.advertisers.create! :name => "Advertiser #{i}" }
    advertiser_ids = group.advertisers(true).map(&:id).sort
    assert 3 <= advertiser_ids.size, "Should have at least 3 advertisers in group"
    assert_not_nil Advertiser.all.detect { |a| !advertiser_ids.include?(a.id) }, "Should have some advertisers not in group"
    
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      action.call
      assert_response :success, "HTTP response code for #{mode}"
      assert_equal @advertiser, assigns(:advertiser), "@advertiser assignment for #{mode}"
      assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
    end
  end
  
  def test_xhr_index_as_owning_publishing_group_user
    group = @publisher.publishing_group
    assert_not_nil group, "Publisher fixture should belong to a publishing group"
    user = User.all.detect { |user| group == user.company }
    assert_not_nil user, "Publishing group should have a user"
    
    2.times { |i| @publisher.advertisers.create! :name => "Advertiser #{i}" }
    advertiser_ids = group.advertisers(true).map(&:id).sort
    assert 3 <= advertiser_ids.size, "Should have at least 3 advertisers in group"
    assert_not_nil Advertiser.all.detect { |a| !advertiser_ids.include?(a.id) }, "Should have some advertisers not in group"
    
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      action.call
      assert_response :success, "HTTP response code for #{mode}"
      assert_equal @advertiser, assigns(:advertiser), "@advertiser assignment for #{mode}"
      assert_equal @advertiser.offers, assigns(:offers), "@offers assignment for #{mode}"
      assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
    end
  end
  
  def test_get_index_as_other_publishing_group_user
    group = @publisher.publishing_group
    assert_not_nil group, "Publisher fixture should belong to a publishing group"
    user = User.all.detect { |user| user.company.is_a?(PublishingGroup) && group != user.company }
    assert_not_nil user, "Publishing group should have a user"
    
    2.times { |i| @publisher.advertisers.create! :name => "Advertiser #{i}" }
    advertiser_ids = group.advertisers(true).map(&:id).sort
    assert 3 <= advertiser_ids.size, "Should have at least 3 advertisers in group"
    assert_not_nil Advertiser.all.detect { |a| !advertiser_ids.include?(a.id) }, "Should have some advertisers not in group"
    
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
        action.call
      end
    end
  end
  
  def test_xhr_index_as_other_publishing_group_user
    group = @publisher.publishing_group
    assert_not_nil group, "Publisher fixture should belong to a publishing group"
    user = User.all.detect { |user| user.company.is_a?(PublishingGroup) && group != user.company }
    assert_not_nil user, "Publishing group should have a user"
    
    2.times { |i| @publisher.advertisers.create! :name => "Advertiser #{i}" }
    advertiser_ids = group.advertisers(true).map(&:id).sort
    assert 3 <= advertiser_ids.size, "Should have at least 3 advertisers in group"
    assert_not_nil Advertiser.all.detect { |a| !advertiser_ids.include?(a.id) }, "Should have some advertisers not in group"
    
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
        action.call
      end
    end
  end
  
  def test_get_index_as_owning_publisher_user
    user = @publisher.users.first
    assert_not_nil user, "Publisher should have a user fixture"

    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      action.call
      assert_response :success, "HTTP response code for #{mode}"
      assert_equal @advertiser, assigns(:advertiser), "@advertiser assignment for #{mode}"
      assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
    end
  end

  def test_xhr_index_as_owning_publisher_user
    user = @publisher.users.first
    assert_not_nil user, "Publisher should have a user fixture"

    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      action.call
      assert_response :success, "HTTP response code for #{mode}"
      assert_equal @advertiser, assigns(:advertiser), "@advertiser assignment for #{mode}"
      assert_equal @advertiser.offers, assigns(:offers), "@offers assignment for #{mode}"
      assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
    end
  end

  def test_get_index_as_other_publisher_user
    user = User.all.detect { |user| user.company.is_a?(Publisher) && @publisher.id != user.company.id }
    assert_not_nil user, "Should have a user fixture for another publisher"

    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
        action.call
      end
    end
  end

  def test_xhr_index_as_other_publisher_user
    user = User.all.detect { |user| user.company.is_a?(Publisher) && @publisher.id != user.company.id }
    assert_not_nil user, "Should have a user fixture for another publisher"

    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
        action.call
      end
    end
  end

  def test_get_index_as_owning_advertiser_user
    user = User.all.detect { |user| @advertiser == user.company }
    assert_not_nil user, "Should have a user fixture for the advertiser"
    
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      action.call
      assert_response :success, "HTTP response code for #{mode}"
      assert_equal @advertiser, assigns(:advertiser), "@advertiser assignment for #{mode}"
      assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
    end
  end
  
  def test_xhr_index_as_owning_advertiser_user
    user = User.all.detect { |user| @advertiser == user.company }
    assert_not_nil user, "Should have a user fixture for the advertiser"
    
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      action.call
      assert_response :success, "HTTP response code for #{mode}"
      assert_equal @advertiser, assigns(:advertiser), "@advertiser assignment for #{mode}"
      assert_equal @advertiser.offers, assigns(:offers), "@offers assignment for #{mode}"
      assert_equal dates, assigns(:dates), "@dates assignment for #{mode}"
    end
  end
  
  def test_get_index_as_other_advertiser_user
    user = User.all.detect { |user| user.company.is_a?(Advertiser) && @advertiser != user.company }
    assert_not_nil user, "Should have a user fixture for another advertiser"
    
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    get_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
        action.call
      end
    end
  end
  
  def test_xhr_index_as_other_advertiser_user
    user = User.all.detect { |user| user.company.is_a?(Advertiser) && @advertiser != user.company }
    assert_not_nil user, "Should have a user fixture for another advertiser"
    
    time = Time.zone.parse("Oct 4, 2008 12:34:56")
    dates = Date.parse("June 1, 2008") .. Date.parse("July 1, 2008")

    xhr_index_with_default_or_given_dates(user, time, dates) do |action, mode, dates|
      assert_raises ActiveRecord::RecordNotFound, "Should raise exception for #{mode}" do
        action.call
      end
    end
  end

  test "index csv with web_offers" do
    Timecop.freeze(Time.zone.local(2008, 1, 5, 12, 34, 56)) do
      publisher  = Factory(:publisher, :offer_has_listing => true)
      advertiser = Factory(:advertiser, :publisher => publisher)
      offer1     = Factory(:offer, :advertiser => advertiser, :account_executive => "Steve Guy", :listing => "345dew")
      offer2     = Factory(:offer, :advertiser => advertiser, :listing => "asd213")
      offer3     = Factory(:offer)

      login_as Factory(:admin)

      dates = Date.parse("June 1, 2008") .. Date.parse("June 8, 2008")

      get :index, {
        :advertiser_id => advertiser.to_param,
        :dates_begin   => dates.begin.to_s, :dates_end => dates.end.to_s,
        :summary       => "web_offers",
        :format        => "csv"
      }

      assert_response :success
      
      headers = [ "Coupon",
                  "Publisher Offer ID",
                  "Impressions",
                  "Clicks",
                  "Click-through Rate (%)",
                  "Prints",
                  "Texts",
                  "Emails",
                  "Calls",
                  "Facebook Shares",
                  "Twitter Shares",
                  "Account Executive" ]

      csv  = FasterCSV.new @response.binary_content
      row0 = csv.shift
      row1 = csv.shift

      assert_equal headers, row0
      assert_equal "345dew", row1[1]
      assert_equal "Steve Guy", row1[11]
    end
  end

  def test_xhr_index_with_web_offers_as_user_for_publisher
    @publisher.advertisers.destroy_all

    advertiser = @publisher.advertisers.create!(:name => "Advertiser 1")
    offer_1 = advertiser.offers.create!(:message => "Advertiser 1 Offer 1", :account_executive => "Steve Guy")
    offer_1.impression_counts.create! :publisher => @publisher, :count => 128, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
    offer_1.impression_counts.create! :publisher => @publisher, :count =>  64, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
    offer_1.impression_counts.create! :publisher => @publisher, :count =>  32, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
    offer_1.impression_counts.create! :publisher => @publisher, :count =>  16, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")

    offer_1.click_counts.create! :publisher => @publisher, :count => 8, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
    offer_1.click_counts.create! :publisher => @publisher, :count => 4, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
    offer_1.click_counts.create! :publisher => @publisher, :count => 2, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
    offer_1.click_counts.create! :publisher => @publisher, :count => 1, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")
    
    offer_1.click_counts.create! :publisher => @publisher, :count => 16, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :mode => "facebook"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  8, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :mode => "facebook"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  4, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :mode => "facebook"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  2, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :mode => "facebook"
    
    offer_1.click_counts.create! :publisher => @publisher, :count => 32, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :mode => "twitter"
    offer_1.click_counts.create! :publisher => @publisher, :count => 16, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :mode => "twitter"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  8, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :mode => "twitter"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  4, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :mode => "twitter"
    
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 02, 2008 12:34:56")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 03, 2008 12:34:56")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")
    
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :email => "joe@gmail.com"
    )
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :email => "jim@gmail.com"
    )
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 02, 2008 12:34:56"), :email => "pip@gmail.com"
    )
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :email => "bif@gmail.com"
    )
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :email => "pat@gmail.com"
    )
    
    offer_2 = advertiser.offers.create!(:message => "Advertiser 1 Offer 2")

    txt_offer_1 = advertiser.txt_offers.create!(:short_code => "898411", :keyword => "SDHFOO", :message => "Advertiser 2 TXT Offer 1")
    txt_offer_1.inbound_txts.create!(
      :message => "FOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745901",
      :accepted_time => Time.zone.parse("May 31, 2008 23:59:59")
    ).txts.each { |txt| txt.update_attributes! :status => "sent" }
    
    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745902",
      :accepted_time => Time.zone.parse("Jun 01, 2008 00:00:00")
    ).txts.each { |txt| txt.update_attributes! :status => "sent" }

    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745903",
      :accepted_time => Time.zone.parse("Jun 02, 2008 12:34:56")
    ).txts.each { |txt| txt.update_attributes! :status => "error" }
    
    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745904",
      :accepted_time => Time.zone.parse("Jun 05, 2008 12:34:56")
    ).txts.each { |txt| txt.update_attributes! :status => "error" }
    
    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745905",
      :accepted_time => Time.zone.parse("Jun 08, 2008 23:59:59")
    ).txts.each { |txt| txt.update_attributes! :status => "sent" }
    
    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745906",
      :accepted_time => Time.zone.parse("Jun 09, 2008 00:00:00")
    ).txts.each { |txt| txt.update_attributes! :status => "sent" }
    
    txt_offer_2 = advertiser.txt_offers.create!(:short_code => "898411", :keyword => "SDHBAR", :message => "Advertiser 2 TXT Offer 2")
      
    user = @publisher.users.first
    assert_not_nil user, "Publisher should have a user fixture"
    @request.session[:user_id] = user.try(:id)

    dates = Date.parse("June 1, 2008") .. Date.parse("June 8, 2008")
    xhr :get, :index, {
      :advertiser_id => advertiser.to_param,
      :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
      :summary => "web_offers",
      :format => "xml"
    }
    assert_response :success
    assert_equal [offer_1, offer_2].sort, assigns(:offers).sort
    assert_equal dates, assigns(:dates)

    expected_response = { "offers" => { "offer" =>
        [{
           "id" => offer_1.id.to_s,
           "offer_name" => "Advertiser 1 Offer 1",
           "impressions_count" => "96",
           "clicks_count" => "14",
           "click_through_rate" => "14.5833333333333",
           "prints_count" => "4",
           "emails_count" => "3",
           "calls_count" => "0",
           "txts_count" => "0",
           "facebooks_count" => "12",
           "twitters_count" => "24",
           "account_executive" => "Steve Guy"
         }, {
           "id" => offer_2.id.to_s,
           "offer_name" => "Advertiser 1 Offer 2",
           "impressions_count" => "0",
           "clicks_count" => "0",
           "click_through_rate" => "0.0",
           "prints_count" => "0",
           "calls_count" => "0",
           "emails_count" => "0",
           "txts_count" => "0",
           "facebooks_count" => "0",
           "twitters_count" => "0",
           "account_executive" => nil 
         }]}}
    assert_equal expected_response, Hash.from_xml(@response.body)
  end
  
  def test_xhr_index_with_txt_offers_as_user_for_publisher
    @publisher.advertisers.destroy_all

    advertiser = @publisher.advertisers.create!(:name => "Advertiser 1")
    offer_1 = advertiser.offers.create!(:message => "Advertiser 1 Offer 1")
    offer_1.impression_counts.create! :publisher => @publisher, :count => 128, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
    offer_1.impression_counts.create! :publisher => @publisher, :count =>  64, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
    offer_1.impression_counts.create! :publisher => @publisher, :count =>  32, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
    offer_1.impression_counts.create! :publisher => @publisher, :count =>  16, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")

    offer_1.click_counts.create! :publisher => @publisher, :count => 8, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
    offer_1.click_counts.create! :publisher => @publisher, :count => 4, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
    offer_1.click_counts.create! :publisher => @publisher, :count => 2, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
    offer_1.click_counts.create! :publisher => @publisher, :count => 1, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")
    
    offer_1.click_counts.create! :publisher => @publisher, :count => 16, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :mode => "facebook"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  8, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :mode => "facebook"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  4, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :mode => "facebook"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  2, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :mode => "facebook"
    
    offer_1.click_counts.create! :publisher => @publisher, :count => 32, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :mode => "twitter"
    offer_1.click_counts.create! :publisher => @publisher, :count => 16, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :mode => "twitter"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  8, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :mode => "twitter"
    offer_1.click_counts.create! :publisher => @publisher, :count =>  4, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :mode => "twitter"
    
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("May 31, 2008 23:59:59")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 02, 2008 12:34:56")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 03, 2008 12:34:56")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59")
    offer_1.leads.create! :publisher => @publisher, :print_me => true, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00")
    
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("May 31, 2008 23:59:59"), :email => "joe@gmail.com"
    )
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 01, 2008 00:00:00"), :email => "jim@gmail.com"
    )
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 02, 2008 12:34:56"), :email => "pip@gmail.com"
    )
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 08, 2008 23:59:59"), :email => "bif@gmail.com"
    )
    offer_1.leads.create!(
      :publisher => @publisher, :email_me => true, :created_at => Time.zone.parse("Jun 09, 2008 00:00:00"), :email => "pat@gmail.com"
    )
    
    offer_2 = advertiser.offers.create!(:message => "Advertiser 1 Offer 2")

    txt_offer_1 = advertiser.txt_offers.create!(:short_code => "898411", :keyword => "SDHFOO", :message => "Advertiser 2 TXT Offer 1")
    txt_offer_1.inbound_txts.create!(
      :message => "FOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745901",
      :accepted_time => Time.zone.parse("May 31, 2008 23:59:59")
    ).txts.each { |txt| txt.update_attributes! :status => "sent" }
    
    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745902",
      :accepted_time => Time.zone.parse("Jun 01, 2008 00:00:00")
    ).txts.each { |txt| txt.update_attributes! :status => "sent" }

    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745903",
      :accepted_time => Time.zone.parse("Jun 02, 2008 12:34:56")
    ).txts.each { |txt| txt.update_attributes! :status => "error" }
    
    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745904",
      :accepted_time => Time.zone.parse("Jun 05, 2008 12:34:56")
    ).txts.each { |txt| txt.update_attributes! :status => "error" }
    
    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745905",
      :accepted_time => Time.zone.parse("Jun 08, 2008 23:59:59")
    ).txts.each { |txt| txt.update_attributes! :status => "sent" }
    
    txt_offer_1.inbound_txts.create!(
      :message => "SDHFOO",
      :keyword => "SDHFOO", :subkeyword => "",
      :server_address => "898411",
      :originator_address => "16266745906",
      :accepted_time => Time.zone.parse("Jun 09, 2008 00:00:00")
    ).txts.each { |txt| txt.update_attributes! :status => "sent" }
    
    txt_offer_2 = advertiser.txt_offers.create!(:short_code => "898411", :keyword => "SDHBAR", :message => "Advertiser 2 TXT Offer 2")
      
    user = @publisher.users.first
    assert_not_nil user, "Publisher should have a user fixture"
    @request.session[:user_id] = user.try(:id)

    dates = Date.parse("June 1, 2008") .. Date.parse("June 8, 2008")
    xhr :get, :index, {
      :advertiser_id => advertiser.to_param,
      :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
      :summary => "txt_offers",
      :format => "xml"
    }
    assert_response :success
    assert_equal [txt_offer_1, txt_offer_2], assigns(:txt_offers)
    assert_equal dates, assigns(:dates)

    expected_response = { "txt_offers" => { "txt_offer" =>
        [{
           "id" => txt_offer_2.id.to_s,
           "keyword" => "SDHBAR",
           "inbound_txts_count" => "0",
           "outbound_txts_count" => "0"
         }, {
           "id" => txt_offer_1.id.to_s,
           "keyword" => "SDHFOO",
           "inbound_txts_count" => "4",
           "outbound_txts_count" => "2"
         }]}}
    assert_equal expected_response, Hash.from_xml(@response.body)
  end
  
  def test_xhr_index_with_gift_certificates
    @publisher.advertisers.destroy_all
    
    advertiser = @publisher.advertisers.create(:name => "A1")
    g_1 = advertiser.gift_certificates.create!(
      :message => "A1G1",
      :value => 40.00,
      :price => 19.99,
      :show_on => "Nov 13, 2008",
      :expires_on => "Nov 17, 2008",
      :number_allocated => 10
    )
    g_2 = advertiser.gift_certificates.create!(
      :message => "A1G2",
      :value => 20.00,
      :price => 9.99,
      :show_on => "Nov 16, 2008",
      :expires_on => "Nov 19, 2008",
      :number_allocated => 20
    )
    i = 10
    purchase = lambda do |gift_certificate, purchase_time, payment_status|
      i += 1
      gift_certificate.purchased_gift_certificates.create!(
        :gift_certificate => gift_certificate,
        :paypal_payment_date => purchase_time,
        :paypal_txn_id => "38D93468JC71666#{i}",
        :paypal_receipt_id => "3625-4706-3930-06#{i}",
        :paypal_invoice => "1234567#{i}",
        :paypal_payment_gross => "%.2f" % gift_certificate.price,
        :paypal_payer_email => "higgins@london.com",
        :payment_status => payment_status
      )
    end
    purchase.call(g_1, "00:00:00 Nov 15, 2008 PST", "completed")
    purchase.call(g_1, "00:00:01 Nov 15, 2008 PST", "reversed")
    purchase.call(g_1, "12:34:56 Nov 15, 2008 PST", "completed")
    purchase.call(g_1, "23:59:59 Nov 15, 2008 PST", "completed")
    purchase.call(g_1, "00:00:00 Nov 16, 2008 PST", "completed")
    purchase.call(g_1, "12:34:56 Nov 16, 2008 PST", "completed")
    purchase.call(g_1, "00:00:00 Nov 17, 2008 PST", "reversed")
    purchase.call(g_1, "23:59:59 Nov 17, 2008 PST", "completed")
      
    purchase.call(g_2, "00:00:00 Nov 16, 2008 PST", "completed")
    purchase.call(g_2, "00:00:01 Nov 16, 2008 PST", "reversed")
    purchase.call(g_2, "12:34:56 Nov 16, 2008 PST", "completed")
    purchase.call(g_2, "23:59:59 Nov 16, 2008 PST", "reversed")
    purchase.call(g_2, "00:00:00 Nov 17, 2008 PST", "completed")
    purchase.call(g_2, "12:34:56 Nov 17, 2008 PST", "completed")
    purchase.call(g_2, "00:00:00 Nov 18, 2008 PST", "completed")
    purchase.call(g_2, "23:59:59 Nov 18, 2008 PST", "completed")
    purchase.call(g_2, "00:00:00 Nov 19, 2008 PST", "refunded")
    purchase.call(g_2, "12:34:56 Nov 19, 2008 PST", "completed")
    purchase.call(g_2, "12:34:56 Nov 19, 2008 PST", "completed")
    purchase.call(g_2, "23:59:59 Nov 16, 2008 PST", "reversed")
    
    login_as @publisher.users.first
    dates = Date.parse("Nov 15, 2008")..Date.parse("Nov 20, 2008")
    xhr :get, :index, {
      :advertiser_id => advertiser.to_param,
      :dates_begin => dates.begin.to_s, :dates_end => dates.end.to_s,
      :summary => "gift_certificates",
      :format => "xml"
    }
    
    gift_certificates = Hash.from_xml(@response.body)["gift_certificates"]["gift_certificate"].sort_by { |gc| gc["purchased_revenue"].to_f }
    
    assert_equal 2, gift_certificates.size
    assert_equal({
      "id" => g_2.id.to_s,
      "item_number" => g_2.item_number,
      "available_count_begin"=>"0",
      "available_revenue_begin"=>"0.00",
      "purchased_count"=>"8",
      "purchased_revenue"=>"79.92",
      "available_count_end"=>"0",
      "available_revenue_end"=>"0.00",
      "currency_symbol"=>"$"
    }, gift_certificates.first, "First gift_certificate hash")
    assert_equal({
      "id" => g_1.id.to_s,
      "item_number" => g_1.item_number,
      "available_count_begin" => "10",
      "available_revenue_begin" => "199.90",
      "purchased_count"=>"6",
      "purchased_revenue" => "119.94",
      "available_count_end" => "0",
      "available_revenue_end" => "0.00",
      "currency_symbol"=>"$"
    }, gift_certificates.last, "Second gift_certificate hash")
  end
    
  private

  def setup_with_user(user)
    @controller = nil
    setup_controller_request_and_response
    @request.session[:user_id] = user.try(:id)
  end
  
  def get_index_with_default_or_given_dates(user, time, dates)
    db, de = [dates.begin, dates.end].map { |date| date.strftime("%B %d, %Y") }
    default_dates = (time.to_date - 7.days) .. time.to_date
    params = { :advertiser_id => @advertiser.to_param }
      
    Time.zone.expects(:now).at_least_once.returns(time)

    setup_with_user user
    action = proc { get :index, params }
    yield action, "get with default dates", default_dates

    setup_with_user user
    action = proc { get :index, params.merge(:dates_begin => db, :dates_end => de) }
    yield action, "get with given dates", dates
  end
  
  def xhr_index_with_default_or_given_dates(user, time, dates)
    db, de = [dates.begin, dates.end].map { |date| date.strftime("%B %d, %Y") }
    default_dates = (time.to_date - 7.days) .. time.to_date
    params = { :advertiser_id => @advertiser.to_param, :format => "xml", :filter => "web" }

    Time.zone.expects(:now).at_least_once.returns(time)

    setup_with_user user
    action = proc { xhr :get, :index, params }
    yield action, "xhr with default dates", default_dates
    
    setup_with_user user
    action = proc { xhr :get, :index, params.merge(:dates_begin => db, :dates_end => de) }
    yield action, "xhr with given dates", dates
  end
end

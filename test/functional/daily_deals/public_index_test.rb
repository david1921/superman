require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::PublicIndexTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  def teardown
    User.current = nil unless User.current.nil?
  end

  test "should filter deals by categories" do
    publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)
    categories = []
    daily_deals = []

    # create multiple deals in each of 3 categories
    3.times do |i|
      categories << category = Factory(:daily_deal_category, :name => "Category #{i}", :publisher => publisher)
      publisher.reload
      2.times do |j|
        daily_deals << Factory(:side_daily_deal, :publisher => publisher, :publishers_category => category)
      end
    end


    # assert that when called with one or two categories, only deals that match are returned
    [[categories.first], categories[0..1]].each do |filter_categories|
      get :public_index, :label => publisher.label, :category => filter_categories.map(&:name)
      assert_response :ok
      assert_not_nil assigns(:daily_deals)

      expected_deals = daily_deals.select { |dd| filter_categories.include? dd.publishers_category }
      expected_deals.each do |daily_deal|
        assert_contains assigns(:daily_deals).map(&:id), daily_deal.id
      end

      unexpected_deals = (daily_deals - expected_deals)
      unexpected_deals.each do |daily_deal|
        assert_does_not_contain assigns(:daily_deals).map(&:id), daily_deal.id
      end
    end
  end

  context "public_index" do

    setup do
      @publisher = Factory :publisher
      @advertiser = Factory :advertiser, :publisher => @publisher
    end

    context "default" do

      context "with no deals" do

        setup do
          get :public_index, :label => @publisher.label
        end

        should respond_with(:success)
        should assign_to( :publisher ).with(@publisher)
        should assign_to( :daily_deals ).with([])
        should assign_to( :side_deals ).with([])
        should "not assign featured_deal" do
          assert_nil assigns(:featured_deal)
        end
        should render_with_layout( :daily_deals )
        should render_template( :public_index )


      end

      context "with active deals" do

        context "with no featured deal" do
          setup do
            @daily_deal     = Factory(:side_daily_deal, :publisher => @publisher)
            @expected_deals = [@daily_deal]
            get :public_index, :label => @publisher.label
          end

          should respond_with(:success)
          should assign_to( :publisher ).with(@publisher)
          should assign_to( :daily_deals ).with(@expected_deals)
          should assign_to( :side_deals ).with(@expected_deals)
          should "not assign featured_deal" do
            assert_nil assigns(:featured_deal)
          end
          should render_with_layout( :daily_deals )
          should render_template( :public_index )
        end

        context "with one featured deal" do

          setup do
            @daily_deal     = Factory(:daily_deal, :publisher => @publisher)
            @expected_deals = [@daily_deal]
            get :public_index, :label => @publisher.label
          end

          should respond_with(:success)
          should assign_to( :publisher ).with(@publisher)
          should assign_to( :daily_deals ).with(@expected_deals)
          should assign_to( :featured_deal ).with(@daily_deal)
          should assign_to( :side_deals ).with([])
          should render_with_layout( :daily_deals )
          should render_template( :public_index )

        end

        context "with two deals, one featured" do

          setup do
            @side_deal = Factory(:side_daily_deal, :value_proposition => "Deal 1", :publisher => @publisher)
            @featured_deal = Factory(:daily_deal, :publisher => @publisher)
            @expected_deals = @publisher.daily_deals.active.in_order
            get :public_index, :label => @publisher.label
          end

          should respond_with(:success)
          should assign_to( :publisher ).with(@publisher)
          should assign_to( :daily_deals ).with(@expected_deals)
          should assign_to( :featured_deal ).with(@featured_deal)
          should "assign side_deal" do
            assign_to( :side_deals).with([@side_deal])
          end
          should render_with_layout( :daily_deals )
          should render_template( :public_index )
        end

      end

      context "with variations" do
        setup do
          @publisher = Factory(:publisher, :enable_daily_deal_variations => true)
          @daily_deal = Factory(:daily_deal, :publisher => @publisher, :price => 25.00)
          @daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :price => 5.00)
          get :public_index, :label => @publisher.label
        end

        should "display the daily deal with variations" do
          respond_with(:success)
          render_template(:public_index)
          assert_select "div.dd_buy_box.variation", 1
          assert_select "div.dd_price.variation", "From $5"
        end
      end

    end

    context "mall filter" do

      setup do
        @older_sm_deal_1 = Factory :daily_deal, :advertiser => @advertiser, :shopping_mall => true,
                           :start_at => 2.months.ago, :hide_at => 1.month.ago
        @older_non_sm_deal_1 = Factory :daily_deal, :advertiser => @advertiser, :shopping_mall => false,
                               :start_at => 2.weeks.ago, :hide_at => 1.week.ago
        @sm_deal_1 = Factory :side_daily_deal, :advertiser => @advertiser, :shopping_mall => true
        @sm_deal_2 = Factory :side_daily_deal, :advertiser => @advertiser, :shopping_mall => true
        @non_sm_deal_1 = Factory :daily_deal, :advertiser => @advertiser, :shopping_mall => false
        @non_sm_deal_2 = Factory :side_daily_deal, :advertiser => @advertiser, :shopping_mall => false
      end

      should "set @daily_deals to only deals whose .shopping_mall? == true, or are featured, when passed mall=1" do
        get :public_index, :label => @publisher.label, :mall => "1"
        assert_response :success
        assert_equal [@sm_deal_1.id, @sm_deal_2.id, @non_sm_deal_1.id], assigns(:daily_deals).map(&:id).sort
      end

      should "set @mall to '1' when passed mall=1" do
        get :public_index, :label => @publisher.label, :mall => "1"
        assert_response :success
        assert_equal '1', assigns(:mall)
      end

      should "set @daily_deals to only deals whose .shopping_mall? == false when passed mall=0" do
        get :public_index, :label => @publisher.label, :mall => "0"
        assert_response :success
        assert_equal [@non_sm_deal_1.id, @non_sm_deal_2.id], assigns(:daily_deals).map(&:id).sort
      end

      should "set @mall to '0' when passed mall=0" do
        get :public_index, :label => @publisher.label, :mall => "0"
        assert_response :success
        assert_equal '0', assigns(:mall)
      end

      should "return all deals when mall param is not passed" do
        get :public_index, :label => @publisher.label
        assert_response :success
        assert_equal [@sm_deal_1.id, @sm_deal_2.id, @non_sm_deal_1.id, @non_sm_deal_2.id], assigns(:daily_deals).map(&:id).sort
      end

      should "set @mall to nil when mall param is not passed" do
        get :public_index, :label => @publisher.label
        assert_response :success
        assert assigns(:mall).nil?
      end

    end

    context "with tampa (creative loafing)" do

      setup do
        @publishing_group = Factory(:publishing_group, :label => "creativeloafing")
        @publisher        = Factory(:publisher, :label => "tampa", :publishing_group => @publishing_group, :enable_publisher_daily_deal_categories => true)
        (1..3).each do |index|
          Factory(:side_daily_deal, :value_proposition => "Deal #{index}", :publisher => @publisher)
        end

      end

      context "with no category" do

        setup do
          @expected_deals = @publisher.daily_deals.active.in_order
          get :public_index, :label => @publisher.label
        end

        should respond_with(:success)

        should "render the tampa daily_deals/public_index template" do
          assert_template "themes/tampa/daily_deals/public_index"
        end

        should "render the tampa layouts/daily_deals" do
          assert_theme_layout "tampa/layouts/daily_deals"
        end

        should "assign daily deals with @expected_deals" do
          assert_equal @expected_deals, assigns(:daily_deals)
        end

      end

      context "with a category" do

        context "with eats category" do

          setup do
            @daily_deal = @publisher.daily_deals.first
            @daily_deal.publishers_category = Factory(:daily_deal_category, :name => "Eats", :publisher_id => @publisher.id)
            @daily_deal.save
            @expected_deals = [@daily_deal]
            get :public_index, :label => @publisher.label, :category => "eats"
          end

          should respond_with(:success)

          should "have publishers_category on daily deal" do
            assert_not_nil @daily_deal.reload.publishers_category
          end

          should "render the tampa daily_deals/public_index template" do
            assert_template "themes/tampa/daily_deals/public_index"
          end

          should "render the tampa layouts/daily_deals" do
            assert_theme_layout "tampa/layouts/daily_deals"
          end

          should "assign daily deals with @expected_deals" do
            assert_equal @expected_deals, assigns(:daily_deals)
          end

          should "render the eats header info" do
            assert_select "div.page_column_2" do
              assert_select "img[src='/themes/tampa/images/backgrounds/eats_header.png']"
              assert_select "p.intro_text", :text => "Let Creative Loafing foot half the bill on fine dining experiences from our participating restaurants. Buy our half-priced deal certificates and get a unique mix of food, atmosphere and culture. Certificates are always limited and can only be purchased from online or your mobile."
            end
          end

        end

      end

    end

    context "consumer daily deal radius filter" do
      setup do
        @publisher.update_attributes(:default_daily_deal_zip_radius => 25)

        advertiser1 = Factory(:advertiser, :publisher => @publisher)
        advertiser1.update_attributes(:stores => [])
        @daily_deal1 = Factory(:side_daily_deal, :advertiser => advertiser1, :national_deal => true)

        advertiser2 = Factory(:advertiser, :publisher => @publisher)
        advertiser2.store.update_attributes(:zip => "01033")
        @daily_deal2 = Factory(:side_daily_deal, :advertiser => advertiser2)

        ZipCode.stubs(:zips_near_zip_and_radius).returns(["98686"])
      end

      context "with no logged in consumer" do
        should "only show deals without a store specified (national deals)" do
          get :public_index, :label => @publisher.label
          assert_equal [@daily_deal1.id], assigns(:daily_deals).map(&:id)
        end
      end

      context "with logged in consumer" do
        setup do
          @consumer = Factory(:consumer, :publisher => @publisher, :zip_code => "98685")
          login_as @consumer
        end

        context "given deals within zip radius" do
          setup do
            advertiser3 = Factory(:advertiser, :publisher => @publisher)
            advertiser3.store.update_attributes(:zip => "98686")
            @daily_deal3 = Factory(:side_daily_deal, :advertiser => advertiser3)
          end

          should "show deals within radius as well as deals without a store (national deals)" do
            get :public_index, :label => @publisher.label
            assert_equal [@daily_deal1.id, @daily_deal3.id], assigns(:daily_deals).map(&:id).sort
          end
        end

        context "given no deals within zip radius" do
          should "only show deals without a store specified (national deals)" do
            get :public_index, :label => @publisher.label
            assert_equal [@daily_deal1.id], assigns(:daily_deals).map(&:id)
          end
        end
      end

    end

  end
  
  context "active and recently finished deals filter" do
    
    setup do
      @publishing_group = Factory :publishing_group, :label => "rr"
      @publisher = Factory :publisher, :publishing_group => @publishing_group, :enable_publisher_daily_deal_categories => true
      @advertiser_1 = Factory :advertiser, :publisher => @publisher
      @advertiser_2 = Factory :advertiser, :publisher => @publisher
      @advertiser_1.store.update_attribute :zip, "12414"
      @advertiser_2.store.update_attribute :zip, "78782"
      @activities_category = @publisher.daily_deal_categories.create(:name => "Activies", :abbreviation => "A")
      @restaurants_category = @publisher.daily_deal_categories.create(:name => "Restaurants", :abbreviation => "R")
      @other_category = @publisher.daily_deal_categories.create(:name => "Other", :abbreviation => "O")
      @current_deal_1 = Factory :daily_deal, :advertiser => @advertiser_1, :publishers_category => @activities_category, :value_proposition => "cd1", :publisher => @publisher, :start_at => 2.days.ago, :hide_at => 3.days.from_now
      @current_deal_2 = Factory :side_daily_deal, :advertiser => @advertiser_2, :value_proposition => "cd2", :publisher => @publisher, :start_at => 1.minute.ago, :hide_at => 2.months.from_now, :shopping_mall => true
      @past_deal_1 = Factory :side_daily_deal, :publishers_category => @activities_category, :value_proposition => "pd1", :publisher => @publisher, :start_at => 2.weeks.ago, :hide_at => 1.week.ago, :shopping_mall => true
      @past_deal_2 = Factory :side_daily_deal, :publishers_category => @restaurants_category, :value_proposition => "pd2", :publisher => @publisher, :start_at => 1.month.ago, :hide_at => 12.days.ago
      @more_than_two_weeks_old_deal = Factory :side_daily_deal, :value_proposition => "olddeal", :publisher => @publisher, :start_at => 1.month.ago, :hide_at => 3.weeks.ago
    end
    
    should "return all active and recently finished deals, with no category or zip radius filter" do
      get :public_index, :label => @publisher.label
      assert_equal %w(cd1 cd2 pd1 pd2), assigns(:available_and_recently_finished_deals).map(&:value_proposition)
    end

    should "filter by category, when specified" do
      get :public_index, :label => @publisher.label, :category => [@activities_category.name]
      assert_equal %w(cd1 pd1), assigns(:available_and_recently_finished_deals).map(&:value_proposition)
    end
    
    should "filter by zip radius, when the publisher has a default daily deal zip radius" do
      consumer = Factory :consumer, :zip_code => "12345"
      login_as consumer
      @publisher.update_attribute :default_daily_deal_zip_radius, 25
      ZipCode.expects(:zips_near_zip_and_radius).times(2).with("12345", 25).returns(["78782"])
      get :public_index, :label => @publisher.label
      assert_equal %w(cd2), assigns(:available_and_recently_finished_deals).map(&:value_proposition)
    end
    
    should "limit to showing at most 24 deals" do
      deals = []
      deals.expects(:[]).with(0..23)
      @controller.expects(:find_available_and_recently_finished_daily_deals).returns(deals)
      get :public_index, :label => @publisher.label
    end
    
    context "with the mall flag set to '1'" do
      
      should "filter available_and_recently_finished_deals to include only deals with shopping_mall set to true" do
        get :public_index, :label => @publisher.label, :mall => "1"
        assert_equal %w(cd2 pd1), assigns(:available_and_recently_finished_deals).map(&:value_proposition)
      end
      
    end
    
    context "with the mall flag set to '0'" do
      
      should "filter available_and_recently_finished_deals to include only deals with shopping_mall set to false" do
        get :public_index, :label => @publisher.label, :mall => "0"
        assert_equal %w(cd1 pd2), assigns(:available_and_recently_finished_deals).map(&:value_proposition)
      end
      
    end
    
    context "for Time Warner" do

      should "show ended deals with Deal Over in the time left to buy and view_deal areas" do
        get :public_index, :label => @publisher.label
        assert_equal 2, @response.body.scan(%r{<span>Deal Over</span>}).size
        assert_equal 2, @response.body.scan(%r{<span.*><a.*>Deal Over</a></span>}).size
      end
      
    end
    
  end

  context "public index json" do
    setup do
      @featured_deal = Factory(:daily_deal,
                               :value_proposition => "featured deal",
                                :start_at => 1.days.ago,
                                :hide_at => 7.days.from_now)
      @publisher = @featured_deal.publisher
      @side_deal_1 = Factory(:side_daily_deal,
                             :publisher => @publisher,
                             :value_proposition => "side deal 1",
                             :start_at => 1.days.ago,
                             :hide_at => 4.days.from_now)
      @side_deal_2 = Factory(:side_daily_deal,
                             :publisher => @publisher,
                             :value_proposition => "side deal 2",
                              :start_at => 2.days.ago,
                              :hide_at => 3.days.from_now)
      @side_deal_3 = Factory(:side_daily_deal,
                             :publisher => @publisher,
                             :value_proposition => "side deal 3",
                             :start_at => 5.days.ago,
                             :hide_at => 6.days.from_now)
      @featured_deal_other_publisher = Factory(:daily_deal)
    end

    should "respond with success" do
      get :public_index, :format => 'json', :label => @publisher.label
      assert_response :success
    end

    should "respond with not found when daily_deal_id is invalid" do
      assert_raises(ActiveRecord::RecordNotFound) do
        get :public_index, :format => 'json', :label => "99999999"
      end
    end

    should "respond with json when side deals present" do
      get :public_index, :format => 'json', :label => @publisher.label
      json = ActiveSupport::JSON.decode( @response.body )
      assert_response :success
      assert json.present?, "Should not have an empty response"
      assert_equal  "side deal 3", json[0]['daily_deal']['title']
      assert_equal  "side deal 2", json[1]['daily_deal']['title']
      assert_equal  "featured deal", json[2]['daily_deal']['title']
      assert_equal  "side deal 1", json[3]['daily_deal']['title']
    end

  end

  context "public_index with template parameter" do

    setup do
      @featured_deal = Factory(:daily_deal,
                               :value_proposition => "featured deal",
                                :start_at => 1.days.ago,
                                :hide_at => 7.days.from_now)
      @publisher = @featured_deal.publisher      
    end

    should "render public_index if the template parameter is not widget" do
      get :public_index, :label => @publisher.label, :template => "blah"
      assert_template :public_index
    end

    should "render widge template if template parameter is widget" do
      get :public_index, :label => @publisher.label, :template => "widget"
      assert_template :widget
      assert_layout nil
    end

  end

end

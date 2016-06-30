require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerMapTest

class Syndication::DealsControllerMapTest < ActionController::TestCase
  include ActionView::Helpers::NumberHelper

  def setup
    @controller = Syndication::DealsController.new
  end
  
  context "map" do
    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @user      = Factory(:user, :company => @publisher, :allow_syndication_access => true)
    end

    context "navigation" do
      setup do
        login_as @user
        get :map
        assert_response :success
      end
      
      should "render correct context" do
        assert_select "#site_nav" do
          assert_select "li.current:nth-child(1)" do
            assert_select "a[href='#{list_syndication_deals_path}']", :text => I18n.t('browse_deals')
          end
          # NOTE: we don't have routes mapped out for my account and logout.
          assert_select "li:nth-child(2)" do
            assert_select "a[href='#{edit_syndication_user_path(@user.id)}']", :text => I18n.t('my_account')
          end
          assert_select "li:nth-child(3)" do
            assert_select "a[href='#{syndication_logout_path}']", :text => I18n.t('logout')
          end
          assert_select "a[href='#{root_path}']", :text => "Manage Deals"
        end
      end
      
      should "render the appropriate view by links" do
        assert_select "#view_select" do
          assert_select "p", :text => "View:"
          assert_select "ul#view_buttons" do
            assert_select "li:nth-child(1)" do
              assert_select "a[href='#{grid_syndication_deals_path(:page => 1)}']", :text => "Grid"
            end
            assert_select "li:nth-child(2)" do
              assert_select "a[href='#{list_syndication_deals_path(:page => 1)}']", :text => "List"
            end
            assert_select "li:nth-child(3)" do
              assert_select "a[href='#{calendar_syndication_deals_path(:page => 1)}']", :text => "Calendar"
            end
            assert_select "li.current:nth-child(4)" do
              assert_select "a[href='#{map_syndication_deals_path(:page => 1)}']", :text => "Map"
            end
          end
        end
      end
    end

    context "deals HTML" do
      setup do
        @deal_available = Factory(:daily_deal_for_syndication, :start_at => 1.day.from_now, :hide_at => 2.days.from_now)
        login_as @user
        get :map
      end

      should render_template(:map)
      should render_with_layout(:syndication)

      should "include a map" do
        assert_select "#aa-map"
      end
    end

    context "deals JSON" do
      setup do
        @deal_available  = Factory(:daily_deal_for_syndication, :start_at => 1.day.from_now, :hide_at => 2.days.from_now)
        @deal_available2 = Factory(:daily_deal_for_syndication, :start_at => 1.day.from_now, :hide_at => 2.days.from_now)
        login_as @user
        get :map, :format => 'json'
      end
      
      should "have stores on @deal_available and @deal_available2" do
        assert @deal_available.advertiser.stores.any?
        assert @deal_available2.advertiser.stores.any?
      end

      should "respond successfully" do
        assert_response :success
      end

      context "formatting" do
        setup do
          @json_response = JSON.parse(@response.body)
        end

        should "have top level items" do
          assert_equal map_syndication_deals_url(:with_map => true, :format => "json"), @json_response["request"]
          assert_equal 1  , @json_response["page"]
          assert_equal 5 , @json_response["page_size"]
          assert_equal 1  , @json_response["page_count"]
          assert_equal 2  , @json_response["total_count"]
        end

        context "daily_deals" do
          setup do
            @daily_deals = @json_response["daily_deals"]
            @json_deal   = @daily_deals.first["daily_deal"]
          end

          should "have two deals" do
            assert_equal 2, @daily_deals.size
          end

          should "have top level items" do
            assert_equal @deal_available.id, @json_deal["id"]
            assert_equal @deal_available.value_proposition, @json_deal["value_proposition"]
            assert_equal @deal_available.hide_at.strftime("%m/%d/%Y"), @json_deal["hide_at"]
            assert_equal @deal_available.start_at.strftime("%m/%d/%Y"), @json_deal["start_at"]
            assert_equal number_to_currency( @deal_available.price, :unit => @deal_available.currency_code ), @json_deal["price"]
          end

          context "store" do
            setup do
              @json_store = @json_deal["stores"].first
              @store      = @deal_available.advertiser.stores.first
            end

            should "have top level items" do
              assert_equal @store.latitude.to_s, @json_store["latitude"]
              assert_equal @store.longitude.to_s, @json_store["longitude"]
            end
          end
        end
      end
    end
    
    context "deals JSON with deals with no stores" do

      setup do
        @deal_available  = Factory(:daily_deal_for_syndication, :start_at => 1.day.from_now, :hide_at => 2.days.from_now)
        @deal_available2 = Factory(:daily_deal_for_syndication, :start_at => 1.day.from_now, :hide_at => 2.days.from_now)
        @deal_available3 = Factory(:daily_deal_for_syndication, :start_at => 1.day.from_now, :hide_at => 2.days.from_now)
        @deal_available4 = Factory(:daily_deal_for_syndication, :start_at => 1.day.from_now, :hide_at => 2.days.from_now)
        
        @deal_available3.advertiser.stores.destroy_all
        @deal_available4.advertiser.stores.first.update_attributes(:longitude => nil, :latitude => nil)
        
        login_as @user
        get :map, :format => 'json'
      end

      should "have stores on @deal_available and @deal_available2" do
        assert @deal_available.advertiser.stores.any?
        assert @deal_available2.advertiser.stores.any?
      end
      
      should "not have stores on @deal_available3" do
        assert @deal_available3.advertiser.stores.empty?
      end
      
      should "have a store on @deal_available4, but no longitude or latitude" do
        assert_equal 1, @deal_available4.advertiser.stores.size
        assert_nil @deal_available4.advertiser.stores.first.longitude
        assert_nil @deal_available4.advertiser.stores.first.latitude
      end

      should "respond successfully" do
        assert_response :success
      end      

      context "formatting" do
        setup do
          @json_response = JSON.parse(@response.body)
        end

        should "have top level items" do
          assert_equal map_syndication_deals_url(:with_map => true, :format => "json"), @json_response["request"]
          assert_equal 1  , @json_response["page"]
          assert_equal 5 , @json_response["page_size"]
          assert_equal 1  , @json_response["page_count"]
          assert_equal 2  , @json_response["total_count"]
        end

        context "daily_deals" do
          setup do
            @daily_deals = @json_response["daily_deals"]
            @json_deal   = @daily_deals.first["daily_deal"]
          end

          should "have two deals" do
            assert_equal 2, @daily_deals.size
          end

          should "have top level items" do
            assert_equal @deal_available.id, @json_deal["id"]
            assert_equal @deal_available.value_proposition, @json_deal["value_proposition"]
            assert_equal @deal_available.hide_at.strftime("%m/%d/%Y"), @json_deal["hide_at"]
            assert_equal @deal_available.start_at.strftime("%m/%d/%Y"), @json_deal["start_at"]
            assert_equal number_to_currency( @deal_available.price, :unit => @deal_available.currency_code ), @json_deal["price"]
          end

          context "store" do
            setup do
              @json_store = @json_deal["stores"].first
              @store      = @deal_available.advertiser.stores.first
            end

            should "have top level items" do
              assert_equal @store.latitude.to_s, @json_store["latitude"]
              assert_equal @store.longitude.to_s, @json_store["longitude"]
            end
          end
        end
      end
      
      
    end
    
  end
end
  

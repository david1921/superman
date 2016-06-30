require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::DealsControllerGridTest

class Syndication::DealsControllerGridTest < ActionController::TestCase
  
  include ActionView::Helpers::TextHelper
  
  def setup
    @controller = Syndication::DealsController.new
    
    @publisher = Factory(:publisher, :self_serve => true)
    @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
    
    @automotive = Factory(:daily_deal_category, :name => "Automotive")
    @education  = Factory(:daily_deal_category, :name => "Education" )
    @travel     = Factory(:daily_deal_category, :name => "Travel" )
    @categories = [@automotive, @education, @travel]
    @search_request_parameters = {
      :filter => {
        :text => "food",
        :national_deals => true,
        :location => "98671",
        :radius => "5",
        :start_date => "12/01/2002",
        :end_date => "06/15/2008",
        :categories => [@automotive.to_param, @education.to_param]
      }
    }
  end
  
  context "sort" do
    
    setup do
      login_as @user
    end
    
    should "render with default sort parameter" do
      get :grid
      assert_response :success
      assert_select "select[name='sort']"
      assert_select "option[value='#{Syndication::SearchRequest::Sort::START_DATE_ASCENDING}'][selected='selected']", :count => 1
      assert_select "option[value='#{Syndication::SearchRequest::Sort::START_DATE_DESCENDING}'][selected='selected']", :count => 0
      assert_select "option[value='#{Syndication::SearchRequest::Sort::PRICE_ASCENDING}'][selected='selected']", :count => 0
      assert_select "option[value='#{Syndication::SearchRequest::Sort::PRICE_DESCENDING}'][selected='selected']", :count => 0
    end
    
    should "render with supplied sort parameter" do
      get :grid, :sort => Syndication::SearchRequest::Sort::PRICE_DESCENDING
      assert_response :success
      assert_select "select[name='sort']"
      assert_select "option[value='#{Syndication::SearchRequest::Sort::START_DATE_ASCENDING}'][selected='selected']", :count => 0
      assert_select "option[value='#{Syndication::SearchRequest::Sort::START_DATE_DESCENDING}'][selected='selected']", :count => 0
      assert_select "option[value='#{Syndication::SearchRequest::Sort::PRICE_ASCENDING}'][selected='selected']", :count => 0
      assert_select "option[value='#{Syndication::SearchRequest::Sort::PRICE_DESCENDING}'][selected='selected']", :count => 1
    end
    
    should "populate sort on search request" do
      get :grid, :sort => Syndication::SearchRequest::Sort::PRICE_DESCENDING
      assert_response :success
      search_request = assigns(:search_request)
      assert search_request
      assert_equal search_request.sort, Syndication::SearchRequest::Sort::PRICE_DESCENDING
    end
    
    should "have filter parameters, status and publisher id" do
      get :list, :search_request => @search_request_parameters
      assert_response :success
      assert_select "#sort_form" do
        assert_select "input[type=hidden][name='search_request[filter][text]'][value='food']"
        assert_select "input[type=hidden][name='search_request[filter][national_deals]']"
        assert_select "input[type=hidden][name='search_request[filter][location]']"
        assert_select "input[type=hidden][name='search_request[filter][radius]']"
        assert_select "input[type=hidden][name='search_request[filter][start_date]']"
        assert_select "input[type=hidden][name='search_request[filter][start_date]']"
        assert_select "input[type=hidden][name='status']"
        assert_select "input[type=hidden][name='publisher_id']"
      end
    end
    
  end
  
  context "filter" do
    
    setup do
      login_as @user
    end
    
    should "have a current page of 1 on search response" do
      get :grid, :search_request => @search_request_parameters
      assert_response :success
      assert_equal 1, assigns(:search_response).current_page
    end
    
    should "have default page size to 9" do
      get :grid, :search_request => @search_request_parameters
      assert_response :success
      assert_equal 9, assigns(:search_request).paging.page_size
    end
    
    should "render with default parameters" do
      get :grid, :search_request => @search_request_parameters
      assert_response :success
      assert_select "#filter_search" do
        assert_select "form[action='#{grid_syndication_deals_path}'][method='get']" do
          assert_select "input[type=hidden][name='page'][value='1']"
          assert_select "input[type=hidden][name='sort']"
          assert_select "input[type=hidden][name='publisher_id']"
          assert_select "input[type=hidden][name='status']"
          assert_select "input[type=text][name='search_request[filter][text]']"
          assert_select "input[type=checkbox][name='search_request[filter][national_deals]']"
          assert_select "input[type=text][name='search_request[filter][location]']"
          assert_select "select[name='search_request[filter][radius]']" do
            assert_select "option:nth-child(1)[value='']", :text => ""
            Syndication::SearchRequest::RADIUS.each_with_index do |mile, index|
              assert_select "option:nth-child(#{index+2})[value='#{mile}']", :text => pluralize(mile, "mile")
            end
          end
          @categories.each do |category|
            assert_select "input[type=checkbox][name='search_request[filter][categories][]'][value='#{category.id}']"
          end
          assert_select "input[type=text][name='search_request[filter][start_date]']"
          assert_select "input[type=text][name='search_request[filter][end_date]']"
          assert_select "input[type='submit'][value='Reset']", :count => 1
          assert_select "input[type='submit'][value='Search']", :count => 1
        end
      end
    end
    
    should "render with supplied parameters" do
      get :grid, :search_request => @search_request_parameters
      assert_response :success
      assert_select "#filter_search" do
        assert_select "form[action='#{grid_syndication_deals_path}'][method='get']" do
          assert_select "input[type=text][name='search_request[filter][text]'][value='#{@search_request_parameters[:filter][:text]}']"
          assert_select "input[type=hidden][name='page'][value='1']"
          assert_select "input[type=checkbox][name='search_request[filter][national_deals]'][checked=checked]"
          assert_select "input[type=text][name='search_request[filter][location]'][value='#{@search_request_parameters[:filter][:location]}']"
          assert_select "select[name='search_request[filter][radius]']" do
            assert_select "option:nth-child(1)[value='']", :text => ""
            Syndication::SearchRequest::RADIUS.each_with_index do |mile, index|
              if mile == @search_request_parameters[:filter][:radius].to_i
                assert_select "option:nth-child(#{index+2})[value='#{mile}'][selected=selected]", :text => pluralize(mile, "mile")
              else
                assert_select "option:nth-child(#{index+2})[value='#{mile}']", :text => pluralize(mile, "mile")
              end
            end
          end
          @categories.each do |category|
            if @search_request_parameters[:filter][:categories].include?( category.id.to_s )
              assert_select "input[type=checkbox][name='search_request[filter][categories][]'][value='#{category.id}'][checked=checked]"
            else
              assert_select "input[type=checkbox][name='search_request[filter][categories][]'][value='#{category.id}']"
            end
          end
          assert_select "input[type=text][name='search_request[filter][start_date]'][value='#{@search_request_parameters[:filter][:start_date]}']"
          assert_select "input[type=text][name='search_request[filter][end_date]'][value='#{@search_request_parameters[:filter][:end_date]}']"              
        end
      end
    end
    
    should "set filter on search request" do
      get :grid, :search_request => @search_request_parameters
      assert_response :success
      search_request = assigns(:search_request)
      assert search_request
      assert_search_request_filter_params_equal(search_request)
    end
    
    context "reset" do
      setup do
        get :grid, :search_request => @search_request_parameters, :reset => 'Reset'
        assert_response :success
      end
      
      should "render with default search request parameters" do
        assert_select "#filter_search" do
          assert_select "form[action='#{grid_syndication_deals_path}'][method='get']" do
            assert_select "input[type=text][name='search_request[filter][text]'][value='Search Deals']"
            assert_select "input[type=hidden][name='page'][value='1']"
            assert_select "input[type=checkbox][name='search_request[filter][national_deals]']"
            assert_select "input[type=text][name='search_request[filter][location]'][value='Zip Code']"
            assert_select "select[name='search_request[filter][radius]']" do
                assert_select "option:nth-child(1)[value='']", :text => ""
                Syndication::SearchRequest::RADIUS.each_with_index do |mile, index|
                  if mile == @search_request_parameters[:filter][:radius].to_i
                    assert_select "option:nth-child(#{index+2})[value='#{mile}']", :text => pluralize(mile, "mile")
                  else
                    assert_select "option:nth-child(#{index+2})[value='#{mile}']", :text => pluralize(mile, "mile")
                  end
                end
              end
              categories.each do |category|
                  assert_select "input[type=checkbox][name='search_request[filter][categories][]'][value='#{category.id}']"
              end
            assert_select "input[type=text][name='search_request[filter][start_date]'][value='mm/dd/yyyy']"
            assert_select "input[type=text][name='search_request[filter][end_date]'][value='mm/dd/yyyy']"              
          end
        end
      end
      
      should "reset search request" do
        search_request = assigns(:search_request)
        assert search_request
        assert_equal search_request.filter.text, nil
        assert_equal search_request.filter.national_deals, nil
        assert_equal search_request.filter.location, nil
        assert_equal search_request.filter.radius, 50 # radius defaults to 50
        assert_equal search_request.filter.start_date, nil
        assert_equal search_request.filter.end_date, nil
        assert_equal search_request.filter.categories, []
      end
      
    end
    
  end
  
  context "sort and filter" do
    setup do
      login_as @user
      get :grid, {:sort => Syndication::SearchRequest::Sort::PRICE_DESCENDING, :search_request => @search_request_parameters}
    end
    
    should "populate all params on search request" do
      assert_response :success
      search_request = assigns(:search_request)
      assert search_request
      assert_equal search_request.sort, Syndication::SearchRequest::Sort::PRICE_DESCENDING
      assert_search_request_filter_params_equal(search_request)
    end
  end
  
  context "paging" do
    
    setup do
      advertiser = Factory(:advertiser, :publisher => @publisher)
      12.times do
        Factory(:side_daily_deal_for_syndication,
                :publisher => @publisher,
                :value_proposition => "Fantastic deal",
                :national_deal => true)
      end
      login_as @user
      get :grid,
          :publisher_id => @publisher.to_param,
          :sort => Syndication::SearchRequest::Sort::PRICE_ASCENDING,
          :search_request => {
            :filter => {:national_deals => true, :text => "Fantastic"}
            }
      assert_response :success
    end
    
    should "render with supplied parameters" do
      assert_select "#deal_pagination" do
        assert_select "a[href*='#{u("page")}=2']", :text => 2
        assert_select "a[href*='#{u("search_request[filter][national_deals]")}=true']", :text => 2
        assert_select "a[href*='#{u("search_request[filter][text]")}=Fantastic']", :text => 2
        assert_select "a[href*='publisher_id=#{@publisher.to_param}']", :text => 2
        assert_select "a[href*='sort=price_asc']", :text => 2
      end
    end
    
  end

  private
  
  def assert_search_request_filter_params_equal(search_request)
    assert_equal search_request.filter.text, "food"
    assert_equal search_request.filter.national_deals, true
    assert_equal search_request.filter.location, "98671"
    assert_equal search_request.filter.radius, "5"
    assert_equal search_request.filter.start_date, "12/01/2002"
    assert_equal search_request.filter.end_date, "06/15/2008"
    assert_equal search_request.filter.categories, [@automotive.to_param, @education.to_param]
  end
  
end

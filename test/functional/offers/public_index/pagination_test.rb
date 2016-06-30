require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class OffersController::PublicIndex::PaginationTest
module OffersController::PublicIndex
  class PaginationTest < ActionController::TestCase
    tests OffersController

    def test_public_index_pagination_with_no_offers
      publisher = Factory(:publisher, :name => "Publisher 1")

      get :public_index, :publisher_id => publisher.to_param
      assert_response(:success)
      assert_equal 0, assigns(:pages)
      assert_select "div.offer", 0
      assert_select "td.pagination", 1
      assert_select "div.page_numbers", 1
    end

    def test_public_index_pagination_with_one_offer
      publisher = Factory(:publisher, :name => "Publisher 1")
      create_offer_for publisher, :index => 0
      publisher.advertisers.create!.offers.create!(:deleted_at => Time.now, :message => "msg")

      get :public_index, :publisher_id => publisher.to_param
      assert_response(:success)
      assert_equal 1, assigns(:pages)
      assert_select "div.offer", 1
      assert_select "td.pagination", 1
      assert_select "div.page_numbers", 1
    end

    def test_public_index_page_out_of_range
      publisher = Factory(:publisher, :name => "Publisher 1")
      create_offer_for publisher, :index => 0
      publisher.advertisers.create!.offers.create!(:message => "msg", :category_names => "Food")
      publisher.advertisers.create!.offers.create!(:message => "msg", :category_names => "Gas")
      food = Category.find_by_name("Food")
      gas = Category.find_by_name("Gas")

      get :public_index, :publisher_id => publisher.to_param,
          :page_size => "4", :page => "13",
          :radius => "", :postal_code => "", :text => "", :categories => [food, gas]
      assert_response(:success)
      assert_equal 1, assigns(:pages)
      assert_equal 1, assigns(:page)
      assert_select "div.offer", 3
      assert_select "td.pagination", 1
      assert_select "div.page_numbers", 1
    end

    def test_public_index_pagination_with_one_full_page
      publisher = Factory(:publisher, :name => "Publisher 1")
      PaginationHelper::DEFAULT_PAGE_SIZE.times { |i| create_offer_for publisher, :index => i }

      get :public_index, :publisher_id => publisher.to_param
      assert_response(:success)
      assert_equal 1, assigns(:pages)
      assert_select "div.offer", PaginationHelper::DEFAULT_PAGE_SIZE
      assert_select "td.pagination", 1
      assert_select "div.page_numbers", 1
    end

    def test_public_index_pagination_with_one_full_page_plus_one_offer
      publisher = Factory(:publisher, :name => "Publisher 1")
      (PaginationHelper::DEFAULT_PAGE_SIZE + 1).times { |i| create_offer_for publisher, :index => i }

      get :public_index, :publisher_id => publisher.to_param

      assert_response(:success)
      assert_equal PaginationHelper::DEFAULT_PAGE_SIZE, assigns(:offers).size, "@offers"
      assert_equal 2, assigns(:pages)
      assert_select "div.offer", PaginationHelper::DEFAULT_PAGE_SIZE
      assert_select "td.pagination", :count => 1, :text => /page/i do
        assert_select "ul.pagination", 1 do
          assert_select "li", 2
          assert_select "li:first-child", "1"
          assert_select "li:first-child a", false
          assert_select "li:last-child > a[href=#{CGI::escapeHTML(public_offers_path(publisher, :page => 2, :page_size => PaginationHelper::DEFAULT_PAGE_SIZE))}]", "2"
        end
      end
    end

    def test_public_index_pagination_with_one_full_page_plus_one_offer_at_page_1
      publisher = Factory(:publisher, :name => "Publisher 1")
      (PaginationHelper::DEFAULT_PAGE_SIZE + 1).times { |i| create_offer_for publisher, :index => i }

      get :public_index, :publisher_id => publisher.to_param, :page => 1
      assert_response(:success)
      assert_equal 2, assigns(:pages)
      assert_select "div.offer", PaginationHelper::DEFAULT_PAGE_SIZE
      assert_select "td.pagination", :count => 1, :text => /page/i do
        assert_select "ul.pagination", 1 do
          assert_select "li", 2
          assert_select "li:first-child", "1"
          assert_select "li:first-child a", false
          assert_select "li:last-child > a[href=#{CGI::escapeHTML(public_offers_path(publisher, :page => 2, :page_size => PaginationHelper::DEFAULT_PAGE_SIZE))}]", "2"
        end
      end
    end

    def test_public_index_pagination_with_one_full_page_plus_one_offer_at_page_2
      publisher = Factory(:publisher, :name => "Publisher 1")
      (PaginationHelper::DEFAULT_PAGE_SIZE + 1).times { |i| create_offer_for publisher, :index => i }

      get :public_index, :publisher_id => publisher.to_param, :page => 2
      assert_response(:success)
      assert_equal 2, assigns(:pages)
      assert_select "div.offer", 1
      assert_select "td.pagination", :count => 1, :text => /page/i do
        assert_select "ul.pagination", 1 do
          assert_select "li", 2
          assert_select "li:first-child > a[href=#{CGI::escapeHTML(public_offers_path(publisher, :page => 1, :page_size => PaginationHelper::DEFAULT_PAGE_SIZE))}]", "1"
          assert_select "li:last-child", "2"
          assert_select "li:last-child a", false
        end
      end
    end

    def test_public_index_pagination_with_one_full_page_plus_one_offer_at_page_1_with_non_default_page_size
      publisher = Factory(:publisher, :name => "Publisher 1")
      page_size = PaginationHelper::DEFAULT_PAGE_SIZE + 2
      (page_size + 1).times { |i| create_offer_for publisher, :index => i }

      get :public_index, :publisher_id => publisher.to_param, :page => 1, :page_size => page_size
      assert_response(:success)
      assert_equal 2, assigns(:pages)
      assert_select "div.offer", page_size
      assert_select "td.pagination", :count => 1, :text => /page/i do
        assert_select "ul.pagination", 1 do
          assert_select "li", 2
          assert_select "li:first-child", "1"
          assert_select "li:first-child a", false
          assert_select "li:last-child > a[href=#{CGI::escapeHTML(public_offers_path(publisher, :page => 2, :page_size => page_size))}]", "2"
        end
      end
    end

    def test_public_index_pagination_with_ten_full_pages_at_page_7_with_order
      publisher = Factory(:publisher, :name => "Publisher 1", :random_coupon_order => true)
      (PaginationHelper::DEFAULT_PAGE_SIZE*10).times { |i| create_offer_for publisher, :index => i }
      publisher.offers(true).each do |offer|
        assert_equal 0, offer.impressions, "Should have no impressions for any offers, but had one for #{offer}"
      end

      get :public_index, :publisher_id => publisher.to_param, :page => 7, :order => 46
      assert_response(:success)
      assert_equal 10, assigns(:pages)
      assert_select "div.offer", PaginationHelper::DEFAULT_PAGE_SIZE
      assert_select "td.pagination", :count => 1, :text => /page/i do
        assert_select "ul.pagination", 1 do
          assert_select "li", 6
          path_for_page = lambda do |page|
            public_offers_path(publisher, :page => page, :page_size => PaginationHelper::DEFAULT_PAGE_SIZE, :order => 46)
          end
          assert_select "li:nth-child(1) > a[href=#{CGI::escapeHTML(path_for_page.call(4))}]", "4"
          assert_select "li:nth-child(2) > a[href=#{CGI::escapeHTML(path_for_page.call(5))}]", "5"
          assert_select "li:nth-child(3) > a[href=#{CGI::escapeHTML(path_for_page.call(6))}]", "6"
          assert_select "li:nth-child(4)", "7"
          assert_select "li:nth-child(4) a", false
          assert_select "li:nth-child(5) > a[href=#{CGI::escapeHTML(path_for_page.call(8))}]", "8"
          assert_select "li:nth-child(6) > a[href=#{CGI::escapeHTML(path_for_page.call(9))}]", "9"
        end
      end

      publisher.offers.each do |offer|
        if assigns(:offers).include?(offer)
          assert_equal 1, offer.impressions, "Should have impression for #{offer} on current page"
        else
          assert_equal 0, offer.impressions, "Should have no impressions for #{offer} on different page"
        end
      end
    end

    def test_public_index_pagination_with_category_restriction_at_default_page
      publisher = Factory(:publisher, :name => "Publisher 1")
      (PaginationHelper::DEFAULT_PAGE_SIZE*3).times { |i| create_offer_for publisher, :index => i }
      category = categories(:household)
      (PaginationHelper::DEFAULT_PAGE_SIZE+1).times { |i| create_offer_for publisher, :index => i, :categories => [category] }

      get :public_index, :publisher_id => publisher.to_param, :category_id => category.to_param
      assert_response(:success)
      assert_equal 2, assigns(:pages)
      assert_select "div.offer", PaginationHelper::DEFAULT_PAGE_SIZE
      assert_select "td.pagination", :count => 1, :text => /page/i do
        assert_select "ul.pagination", 1 do
          assert_select "li", 2
          assert_select "li:first-child", "1"
          assert_select "li:first-child a", false
          params = {:category_id => category.to_param, :page => 2, :page_size => PaginationHelper::DEFAULT_PAGE_SIZE}
          assert_select "li:last-child > a[href=#{CGI::escapeHTML(public_offers_path(publisher, params))}]", "2"
        end
      end
      assert_equal_arrays([category], assigns(:categories), "@categories")
      assert_equal(categories(:household), assigns(:category), "@category")
    end

    def test_public_index_pagination_with_category_restriction_at_specific_page
      publisher = Factory(:publisher, :name => "Publisher 1")
      (PaginationHelper::DEFAULT_PAGE_SIZE*3).times { |i| create_offer_for publisher, :index => i }
      category = categories(:household)
      (PaginationHelper::DEFAULT_PAGE_SIZE+1).times { |i| create_offer_for publisher, :index => i, :categories => [category] }

      get :public_index, :publisher_id => publisher.to_param, :category_id => category.to_param, :page => 2
      assert_response(:success)
      assert_equal 2, assigns(:pages)
      assert_select "div.offer", 1
      assert_select "td.pagination", :count => 1, :text => /page/i do
        assert_select "ul.pagination", 1 do
          assert_select "li", 2
          params = {:category_id => category.to_param, :page => 1, :page_size => PaginationHelper::DEFAULT_PAGE_SIZE}
          assert_select "li:first-child > a[href=#{CGI::escapeHTML(public_offers_path(publisher, params))}]", "1"
          assert_select "li:last-child", "2"
          assert_select "li:last-child a", false
        end
      end
    end

    def test_public_index_pagination_with_category_restriction_at_default_page_with_non_default_page_size
      publisher = Factory(:publisher, :name => "Publisher 1")
      page_size = PaginationHelper::DEFAULT_PAGE_SIZE + 4
      (page_size * 3).times { |i| create_offer_for publisher, :index => i }
      category = categories(:household)
      (page_size + 1).times { |i| create_offer_for publisher, :index => i, :categories => [category] }

      get :public_index, :publisher_id => publisher.to_param, :category_id => category.to_param, :page_size => page_size
      assert_response(:success)
      assert_equal 2, assigns(:pages)
      assert_select "div.offer", page_size
      assert_select "td.pagination", :count => 1, :text => /page/i do
        assert_select "ul.pagination", 1 do
          assert_select "li", 2
          assert_select "li:first-child", "1"
          assert_select "li:first-child a", false
          params = {:category_id => category.to_param, :page => 2, :page_size => page_size}
          assert_select "li:last-child > a[href=#{CGI::escapeHTML(public_offers_path(publisher, params))}]", "2"
        end
      end
    end

    def test_public_index_pagination_with_category_restriction_at_specific_page_with_non_default_page_size
      publisher = Factory(:publisher, :name => "Publisher 1")
      page_size = PaginationHelper::DEFAULT_PAGE_SIZE + 4
      (page_size * 3).times { |i| create_offer_for publisher, :index => i }
      category = categories(:household)
      (page_size + 1).times { |i| create_offer_for publisher, :index => i, :categories => [category] }

      get :public_index, :publisher_id => publisher.to_param, :category_id => category.to_param, :page => 2, :page_size => page_size
      assert_response(:success)
      assert_equal 2, assigns(:pages)
      assert_select "div.offer", 1
      assert_select "td.pagination", :count => 1, :text => /page/i do
        assert_select "ul.pagination", 1 do
          assert_select "li", 2
          params = {:category_id => category.to_param, :page => 1, :page_size => page_size}
          assert_select "li:first-child > a[href=#{CGI::escapeHTML(public_offers_path(publisher, params))}]", "1"
          assert_select "li:last-child", "2"
          assert_select "li:last-child a", false
        end
      end
    end

    def test_public_index_pagination_with_page_size
      publisher = Factory(:publisher, :name => "Publisher 1")
      5.times { |i| create_offer_for publisher, :index => i }

      get :public_index, :publisher_id => publisher.to_param, :page_size => 2
      assert_response(:success)
      assert_equal 3, assigns(:pages)
      assert_select "div.offer", 2
      assert_select "td.pagination", 1
      assert_select "td.pagination:empty", 0
    end
  end
end
require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class OffersController::PublicIndex::SearchTest
module OffersController::PublicIndex
  class SearchTest < ActionController::TestCase
    tests OffersController

    def test_search_by_category_different_case
      get :public_index, :publisher_id => publishers(:my_space).to_param, :text => "restaurants"
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal 1, assigns(:offers).size, "Number of offers"
      assert_equal("restaurants", assigns(:text), "assigns @text")
    end

    def test_search_by_category
      get :public_index, :publisher_id => publishers(:my_space).to_param, :text => "Restaurants"
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal 1, assigns(:offers).size, "Number of offers"
      assert_equal("Restaurants", assigns(:text), "assigns @text")
    end

    def test_search_by_advertiser_name
      get :public_index, :publisher_id => publishers(:my_space).to_param, :text => "Burger King"
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal 1, assigns(:offers).size, "Number of offers"
      assert_equal("Burger King", assigns(:text), "assigns @text")
    end

    def test_search_by_invalid_advertiser_name
      get :public_index, :publisher_id => publishers(:my_space).to_param, :text => "Blah"
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal 0, assigns(:offers).size, "Number of offers"
      assert_equal("Blah", assigns(:text), "assigns @text")
    end

    def test_search_by_zip
      offer = offers(:my_space_burger_king_free_fries)
      offer.advertiser.stores.create(:address_line_1 => "1 Main St", :city => "Eaton", :state => "NY", :zip => "13334").save!

      advertiser_2 = publishers(:my_space).advertisers.create!(:name => "Advertiser 2")
      advertiser_2.stores.create(:address_line_1 => "2 Main St", :city => "Nowhere", :state => "NY", :zip => "23411").save!
      offer_2 = advertiser_2.offers.create!(:message => "Offer 2")
      ZipCode.create! :city => "Nowhere", :state => "NY", :zip => "23411", :latitude => 43, :longitude => 43

      get :public_index, :publisher_id => publishers(:my_space).to_param, :text => "23411"
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal_arrays [offer_2], assigns(:offers), "offers"
      assert_equal("23411", assigns(:text), "assigns @text")
    end

    def test_search_by_city_state_locm
      publisher = publishers(:locm)
      advertiser = publisher.advertisers.create!(:listing => "1234")
      advertiser.stores.create(:address_line_1 => "1 Main St", :city => "San Diego", :state => "CA", :zip => "92106").save!
      advertiser.offers.create!(:message => "msg")

      advertiser_2 = publisher.advertisers.create!(:name => "Advertiser 2", :listing => "1235")
      advertiser_2.stores.create(:address_line_1 => "2 Main St", :city => "San Diego", :state => "CA", :zip => "92040").save!
      advertiser_2.offers.create!(:message => "Offer 2")

      get :public_index, :publisher_id => publisher.to_param, :city => "San Diego", :state => "CA"
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal 1, assigns(:offers).size, "Number of offers"
      assert_equal 1, assigns(:offers_count), "@offers_count"
      assert_equal("San Diego", assigns(:city), "assigns @city")
      assert_equal("CA", assigns(:state), "assigns @state")
    end

    def test_search_by_city_state_and_zip_locm
      publisher = publishers(:locm)
      advertiser_1 = publisher.advertisers.create!(:listing => '1234')
      advertiser_1.stores.create(:address_line_1 => '123 Main St', :city => "San Diego", :state => "CA", :zip => '92101').save!
      offer_1 = advertiser_1.offers.create(:message => 'advertiser 1 message')

      advertiser_2 = publisher.advertisers.create!(:listing => '5678')
      advertiser_2.stores.create(:address_line_1 => '123 W Howell St', :city => "San Diego", :state => "CA", :zip => '92106').save!
      offer_2 = advertiser_2.offers.create(:message => 'advertiser 2 message')

      get :public_index, :publisher_id => publisher.to_param, :city => "San Diego", :state => "CA", :text => "92101"
      assert_response(:success)
      assert_not_nil(assigns(:offers), 'assigns @offers')
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal_arrays [offer_1], assigns(:offers), "offers"
      assert_equal 2, assigns(:offers_count), "@offers_count"
    end

    def test_search_by_city_state_and_exact_zip_locm
      publisher = publishers(:locm)
      advertiser_1 = publisher.advertisers.create!(:listing => '1234')
      advertiser_1.stores.create(:address_line_1 => '123 Main St', :city => "San Diego", :state => "CA", :zip => '92101').save!
      offer_1 = advertiser_1.offers.create(:message => 'advertiser 1 message')

      advertiser_2 = publisher.advertisers.create!(:listing => '5678')
      advertiser_2.stores.create(:address_line_1 => '123 W Howell St', :city => "San Diego", :state => "CA", :zip => '92106').save!
      offer_2 = advertiser_2.offers.create(:message => 'advertiser 2 message')

      get :public_index, :publisher_id => publisher.to_param, :city => "San Diego", :state => "CA", :text => "92106"
      assert_response(:success)
      assert_not_nil(assigns(:offers), 'assigns @offers')
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal_arrays [offer_2], assigns(:offers), "offers"
      assert_equal 2, assigns(:offers_count), "@offers_count"
    end

    def test_search_by_bad_city_state_locm
      publisher = publishers(:locm)
      advertiser = publisher.advertisers.create!(:listing => "1234")
      advertiser.stores.create(:address_line_1 => "1 Main St", :city => "San Diego", :state => "CA", :zip => "92106").save!
      advertiser.offers.create!(:message => "msg")

      advertiser_2 = publisher.advertisers.create!(:name => "Advertiser 2", :listing => "1235")
      advertiser_2.stores.create(:address_line_1 => "2 Main St", :city => "San Diego", :state => "CA", :zip => "92040").save!
      advertiser_2.offers.create!(:message => "Offer 2")

      get :public_index, :publisher_id => publisher.to_param, :city => "Neverland", :state => "AB"
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal 0, assigns(:offers).size, "Number of offers"
      assert_equal("Neverland", assigns(:city), "assigns @city")
      assert_equal("AB", assigns(:state), "assigns @state")
    end

    def test_search_by_zip_and_radius
      offer = offers(:my_space_burger_king_free_fries)
      offer.advertiser.stores.create(:address_line_1 => "1 Main St", :city => "San Diego", :state => "CA", :zip => "92106").save!

      advertiser_2 = publishers(:my_space).advertisers.create!(:name => "Advertiser 2")
      advertiser_2.stores.create(:address_line_1 => "2 Main St", :city => "San Diego", :state => "CA", :zip => "92040").save!
      advertiser_2.offers.create!(:message => "Offer 2")

      get :public_index, :publisher_id => publishers(:my_space).to_param, :postal_code => "92101", :radius => "4"
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal 1, assigns(:offers).size, "Number of offers"
      assert_equal("92101", assigns(:postal_code), "assigns @postal_code")
      assert_equal("4", assigns(:radius), "assigns @radius")
    end

    def test_search_by_zip_param
      offer = offers(:my_space_burger_king_free_fries)
      offer.advertiser.stores.create(:address_line_1 => "1 Main St", :city => "San Diego", :state => "CA", :zip => "92101").save!

      advertiser_2 = publishers(:my_space).advertisers.create!(:name => "Advertiser 2")
      advertiser_2.stores.create(:address_line_1 => "2 Main St", :city => "Cazenovia", :state => "NY", :zip => "13035").save!
      advertiser_2.offers.create!(:message => "Offer 2")

      get :public_index, :publisher_id => publishers(:my_space).to_param, :postal_code => "92101", :radius => 20
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal 1, assigns(:offers).size, "Number of offers"
      assert_equal(nil, assigns(:text), "assigns @text")
    end

    def test_search_no_match
      get :public_index, :publisher_id => publishers(:my_space).to_param, :text => "Saturday Night Fever"
      assert_response(:success)
      assert_not_nil(assigns(:offers), "assigns @offers")
      assert_not_nil(assigns(:publisher_categories), "assigns @publisher_categories")
      assert_layout("offers/public_index")
      assert_equal 0, assigns(:offers).size, "Number of offers"
      assert_equal("Saturday Night Fever", assigns(:text), "assigns @text")
    end
  end
end
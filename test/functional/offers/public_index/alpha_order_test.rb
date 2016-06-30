require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class OffersController::PublicIndex::AlphaOrderTest
module OffersController::PublicIndex
  class AlphaOrderTest < ActionController::TestCase
    tests OffersController

    def test_public_index_alpha_order_with_all_offers_being_category_featured_except_my_space_offer_with_no_category_id

      publisher = publishers(:my_space)

      category = publisher.offers.first.categories.first

      performance = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "Offer 1", :featured => 'category')
      performance.categories << category
      performance.save

      excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!(:message => "Offer 1", :featured => 'category')
      excell.categories << category
      excell.save

      colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!(:message => "Offer 1", :featured => 'category')
      colorado.categories << category
      colorado.save

      get :public_index, :publisher_id => publisher.to_param

      assert_response(:success)
      assert_nil assigns(:order), "@order"
      burger_king = offers(:my_space_burger_king_free_fries)
      expected_offers = [burger_king, colorado, excell, performance]
      offers = assigns(:offers)
      assert_equal expected_offers, offers, "Should sort coupons in alpha-order since there is no category filter"

    end

    def test_public_index_alpha_order_with_all_offers_being_category_featured_except_my_space_offer_with_a_category_id

      publisher = publishers(:my_space)

      category = publisher.offers.first.categories.first

      performance = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "Offer 1", :featured => 'category')
      performance.categories << category
      performance.save

      excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!(:message => "Offer 1", :featured => 'category')
      excell.categories << category
      excell.save

      colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!(:message => "Offer 1", :featured => 'category')
      colorado.categories << category
      colorado.save

      get :public_index, :publisher_id => publisher.to_param, :category_id => category.to_param

      assert_response(:success)
      assert_nil assigns(:order), "@order"
      burger_king = offers(:my_space_burger_king_free_fries)
      expected_offers = [colorado, excell, performance, burger_king]
      offers = assigns(:offers)
      assert_equal expected_offers, offers, "Should sort coupons in alpha-order (except burger_king), since there is a category filter"

    end

    def test_public_index_alpha_order_with_all_offers_being_both_featured_except_my_space_offer_with_a_category_id

      publisher = publishers(:my_space)

      category = publisher.offers.first.categories.first

      performance = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "Offer 1", :featured => 'both')
      performance.categories << category
      performance.save

      excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!(:message => "Offer 1", :featured => 'both')
      excell.categories << category
      excell.save

      colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!(:message => "Offer 1", :featured => 'both')
      colorado.categories << category
      colorado.save

      get :public_index, :publisher_id => publisher.to_param, :category_id => category.to_param

      assert_response(:success)
      assert_nil assigns(:order), "@order"
      burger_king = offers(:my_space_burger_king_free_fries)
      expected_offers = [colorado, excell, performance, burger_king]
      offers = assigns(:offers)
      assert_equal expected_offers, offers, "Should sort coupons in alpha-order (except burger_king), since there is a category filter"

    end

    def test_public_index_alpha_order_with_all_offers_being_all_featured_except_my_space_offer_with_a_category_id

      publisher = publishers(:my_space)

      category = publisher.offers.first.categories.first

      performance = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "Offer 1", :featured => 'all')
      performance.categories << category
      performance.save

      excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!(:message => "Offer 1", :featured => 'all')
      excell.categories << category
      excell.save

      colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!(:message => "Offer 1", :featured => 'all')
      colorado.categories << category
      colorado.save

      get :public_index, :publisher_id => publisher.to_param, :category_id => category.to_param

      assert_response(:success)
      assert_nil assigns(:order), "@order"
      burger_king = offers(:my_space_burger_king_free_fries)
      expected_offers = [burger_king, colorado, excell, performance]
      offers = assigns(:offers)
      assert_equal expected_offers, offers, "Should sort coupons in alpha-order since we aren't featured_with_category for each offer"

    end

    def test_public_index_alpha_order_with_one_offer_being_category_featured_with_no_category_id

      publisher = publishers(:my_space)

      category = publisher.offers.first.categories.first

      performance = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "Offer 1")
      performance.categories << category
      performance.save

      excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!(:message => "Offer 1", :featured => "category")
      excell.categories << category
      excell.save

      colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!(:message => "Offer 1")
      colorado.categories << category
      colorado.save

      get :public_index, :publisher_id => publisher.to_param

      assert excell.featured?
      assert_response(:success)
      assert_nil assigns(:order), "@order"
      burger_king = offers(:my_space_burger_king_free_fries)
      expected_offers = [burger_king, colorado, excell, performance]
      offers = assigns(:offers)
      assert_equal expected_offers, offers, "Should sort coupons in alpha-order since there is no category"

    end

    def test_public_index_alpha_order_with_one_offer_being_all_featured_with_no_category_id

      publisher = publishers(:my_space)

      category = publisher.offers.first.categories.first

      performance = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "Offer 1")
      performance.categories << category
      performance.save

      excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!(:message => "Offer 1", :featured => "all")
      excell.categories << category
      excell.save

      colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!(:message => "Offer 1")
      colorado.categories << category
      colorado.save

      get :public_index, :publisher_id => publisher.to_param

      assert excell.featured?
      assert_response(:success)
      assert_nil assigns(:order), "@order"
      burger_king = offers(:my_space_burger_king_free_fries)
      expected_offers = [excell, burger_king, colorado, performance]
      offers = assigns(:offers)
      assert_equal expected_offers, offers, "Should sort coupons in alpha-order except excell should be first since it's featured all"

    end

    def test_public_index_alpha_order_with_all_offers_being_all_featured_with_no_category_id

      publisher = publishers(:my_space)

      category = publisher.offers.first.categories.first

      performance = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "Offer 1", :featured => "all")
      performance.categories << category
      performance.save

      excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!(:message => "Offer 1", :featured => "all")
      excell.categories << category
      excell.save

      colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!(:message => "Offer 1", :featured => "all")
      colorado.categories << category
      colorado.save

      get :public_index, :publisher_id => publisher.to_param

      assert excell.featured?
      assert_response(:success)
      assert_nil assigns(:order), "@order"
      burger_king = offers(:my_space_burger_king_free_fries)
      expected_offers = [colorado, excell, performance, burger_king]
      offers = assigns(:offers)
      assert_equal expected_offers, offers, "Should sort coupons in alpha-order except burger king should be last since it's not featured"

    end

    def test_public_index_alpha_order_with_one_offer_being_category_featured_with_valid_category_id

      publisher = publishers(:my_space)

      category = publisher.offers.first.categories.first

      performance = publisher.advertisers.create!(:name => "Performance").offers.create!(:message => "Offer 1")
      performance.categories << category
      performance.save

      excell = publisher.advertisers.create!(:name => "Excell Sports").offers.create!(:message => "Offer 1", :featured => "category")
      excell.categories << category
      excell.save

      colorado = publisher.advertisers.create!(:name => "Colorado Cyclist").offers.create!(:message => "Offer 1")
      colorado.categories << category
      colorado.save

      get :public_index, :publisher_id => publisher.to_param, :category_id => category.to_param

      assert excell.featured?
      assert_response(:success)
      assert_nil assigns(:order), "@order"
      burger_king = offers(:my_space_burger_king_free_fries)
      expected_offers = [excell, burger_king, colorado, performance]
      offers = assigns(:offers)
      assert_equal expected_offers, offers, "Should sort coupons with featured first, then alpha-numerically"

    end
  end
end
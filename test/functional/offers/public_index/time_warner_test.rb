require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class OffersController::PublicIndex::TimeWarnerTest
module OffersController::PublicIndex
  class TimeWarnerTest < ActionController::TestCase
    tests OffersController

    def test_public_index_for_time_warner_cable_with_withtheme_theme
      publishing_group = Factory(:publishing_group, :label => "rr", :name => "Time Warner Cable")
      ['clickedin-austin', 'clickedin-dallas', 'clickedin-sanantonio'].each do |label|
        publisher = Factory(:publisher, :name => label, :label => label, :publishing_group_id => publishing_group.id, :theme => 'withtheme')

        get :public_index, :publisher_id => publisher.id
        assert_response :success

        assert_theme_layout "rr/layouts/public_index"
        assert_template "themes/rr/offers/public_index"

      end
    end

    def test_public_index_for_time_warner_cable_with_withtheme_theme_with_at_least_one_offer
      publishing_group = Factory(:publishing_group, :label => "rr", :name => "Time Warner Cable")
      publisher = Factory(:publisher, :name => 'clickedin-austin', :label => 'clickedin-austin', :publishing_group_id => publishing_group.id, :theme => 'withtheme')
      advertiser = Factory(:advertiser, :publisher_id => publisher.id)
      offer = Factory(:offer, :value_proposition => "This is the value proposition", :advertiser_id => advertiser.id)

      get :public_index, :publisher_id => publisher.id
      assert_response :success

      assert_theme_layout "rr/layouts/public_index"
      assert_template "themes/rr/offers/public_index"
      assert assigns(:offers).present?
      assert_select "div#side_deals", false, "there should not be a side deal section"
    end

  end
end
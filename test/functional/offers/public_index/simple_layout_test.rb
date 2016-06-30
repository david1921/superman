require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class OffersController::PublicIndex::SimpleLayoutTest
module OffersController::PublicIndex
  class SimpleLayoutTest < ActionController::TestCase
    tests OffersController

    def test_public_index_with_simple_layout_with_at_least_on_offer
      publisher = publishers(:my_space)
      publisher.update_attributes({:theme => 'simple'})
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      assert 'simple', publisher.theme

      get(:public_index, :publisher_id => publisher.to_param)

      assert_select "div.front_panel" do
        assert_select 'div.body'
        assert_select 'div.coupon_code'
        assert_select 'div.footer'
      end
    end

    def test_public_index_with_simple_layout_and_show_bottom_pagination_set_to_true
      publisher = publishers(:my_space)
      publisher.update_attributes({:show_bottom_pagination => true, :theme => 'simple'})
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      assert publisher.show_bottom_pagination?

      get(:public_index, :publisher_id => publisher.to_param)

      assert_select 'td.pagination', 2
    end

    def test_public_index_with_simple_layout_and_show_bottom_pagination_set_to_false
      publisher = publishers(:my_space)
      publisher.update_attributes({:show_bottom_pagination => false, :theme => 'simple'})
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      assert !publisher.show_bottom_pagination?

      get(:public_index, :publisher_id => publisher.to_param)
      assert_select 'td.pagination', 1
    end

    def test_public_index_with_simple_layout_and_show_small_icons_set_to_false
      publisher = publishers(:my_space)
      publisher.update_attributes({:show_small_icons => false})
      advertiser = publisher.advertisers.create!
      advertiser.update_attribute(:coupon_clipping_modes, [:call, :email, :txt].to_set)
      advertiser.offers.create!(:message => "Free yogurt with your taco", :txt_message => "hello there")

      assert !publisher.show_small_icons
      assert advertiser.allows_clipping_via(:call), "allow for calling mode"
      assert advertiser.allows_clipping_via(:email), "allow for emailing coupon"
      assert advertiser.allows_clipping_via(:txt), "allow for txting coupon"

      get(:public_index, :publisher_id => publisher.to_param)

      assert_select "div.footer" do
        assert_select "a.clip"
        assert_select "a.email"
        assert_select "a.call"
        assert_select "a.txt"
      end
    end

    def test_public_index_with_simple_layout_and_show_small_icons_set_to_true
      publisher = publishers(:my_space)
      publisher.update_attributes({:show_small_icons => true})
      advertiser = publisher.advertisers.create!
      advertiser.update_attribute(:coupon_clipping_modes, [:call, :email, :txt].to_set)
      advertiser.offers.create!(:message => "Free yogurt with your taco", :txt_message => "hello there")

      assert publisher.show_small_icons
      assert advertiser.allows_clipping_via(:call), "allow for calling mode"
      assert advertiser.allows_clipping_via(:email), "allow for emailing coupon"
      assert advertiser.allows_clipping_via(:txt), "allow for txting coupon"

      get(:public_index, :publisher_id => publisher.to_param)

      assert_select "div.footer_small" do
        assert_select "a.clip_small"
        assert_select "a.email_small"
        assert_select "a.call_small"
        assert_select "a.txt_small"
      end
    end

    def test_public_index_with_simple_layout_and_show_small_icons_set_to_true_along_with_show_twitter_and_facebook_buttons
      publisher = publishers(:my_space)
      publisher.update_attributes({:show_small_icons => true, :show_twitter_button => true, :show_facebook_button => true})
      advertiser = publisher.advertisers.create!
      advertiser.update_attribute(:coupon_clipping_modes, [:call, :email, :txt].to_set)
      advertiser.offers.create!(:message => "Free yogurt with your taco", :txt_message => "hello there")

      assert publisher.show_small_icons
      assert publisher.show_twitter_button
      assert publisher.show_facebook_button
      assert advertiser.allows_clipping_via(:call), "allow for calling mode"
      assert advertiser.allows_clipping_via(:email), "allow for emailing coupon"
      assert advertiser.allows_clipping_via(:txt), "allow for txting coupon"

      get(:public_index, :publisher_id => publisher.to_param)

      assert_select "div.footer_small" do
        assert_select "a.clip_small"
        assert_select "a.email_small"
        assert_select "a.call_small"
        assert_select "a.txt_small"
        assert_select "a.facebook_small"
        assert_select "a.twitter_small"
      end
    end
  end
end
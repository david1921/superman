require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class OffersController::PublicIndex::EnhancedLayoutTest
module OffersController::PublicIndex
  class EnhancedLayoutTest < ActionController::TestCase
    tests OffersController

    def test_public_index_with_enhanced_layout_with_at_least_on_offer
      publisher = publishers(:my_space)
      publisher.update_attributes({:theme => 'enhanced'})
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      assert 'enhanced', publisher.theme

      get(:public_index, :publisher_id => publisher.to_param)

      assert_select "div.front_panel" do
        assert_select 'div.top'
        assert_select 'div.clip'
      end
    end

    def test_public_index_with_enhanced_layout_and_show_small_icons_set_to_false
      publisher = publishers(:my_space)
      publisher.update_attributes({:show_small_icons => false, :theme => 'enhanced'})
      advertiser = publisher.advertisers.create!
      advertiser.update_attribute(:coupon_clipping_modes, [:call, :email, :txt].to_set)
      advertiser.offers.create!(:message => "Free yogurt with your taco", :txt_message => "hello there")

      assert !publisher.show_small_icons
      assert_equal 'enhanced', publisher.theme

      assert advertiser.allows_clipping_via(:call), "allow for calling mode"
      assert advertiser.allows_clipping_via(:email), "allow for emailing coupon"
      assert advertiser.allows_clipping_via(:txt), "allow for txting coupon"

      get(:public_index, :publisher_id => publisher.to_param)

      assert_select "div.clip" do
        assert_select "a.clip"
        assert_select "a.email"
        assert_select "a.call"
        assert_select "a.txt"
      end
    end

    def test_public_index_with_enhanced_layout_and_show_small_icons_set_to_true
      publisher = publishers(:my_space)
      publisher.update_attributes({:show_small_icons => true, :theme => 'enhanced'})
      advertiser = publisher.advertisers.create!
      advertiser.update_attribute(:coupon_clipping_modes, [:call, :email, :txt].to_set)
      advertiser.offers.create!(:message => "Free yogurt with your taco", :txt_message => "hello there")

      assert publisher.show_small_icons
      assert_equal 'enhanced', publisher.theme

      assert advertiser.allows_clipping_via(:call), "allow for calling mode"
      assert advertiser.allows_clipping_via(:email), "allow for emailing coupon"
      assert advertiser.allows_clipping_via(:txt), "allow for txting coupon"

      get(:public_index, :publisher_id => publisher.to_param)

      assert_select "div.clip_small" do
        assert_select "a.clip_small"
        assert_select "a.email_small"
        assert_select "a.call_small"
        assert_select "a.txt_small"
      end
    end

    def test_public_index_with_enhanced_layout_and_show_small_icons_set_to_true_along_with_show_twitter_and_facebook_buttons
      publisher = publishers(:my_space)
      publisher.update_attributes({:show_small_icons => true, :theme => 'enhanced', :show_twitter_button => true, :show_facebook_button => true})
      advertiser = publisher.advertisers.create!
      advertiser.update_attribute(:coupon_clipping_modes, [:call, :email, :txt].to_set)
      advertiser.offers.create!(:message => "Free yogurt with your taco", :txt_message => "hello there")

      assert publisher.show_small_icons
      assert publisher.show_twitter_button
      assert publisher.show_facebook_button
      assert_equal 'enhanced', publisher.theme

      assert advertiser.allows_clipping_via(:call), "allow for calling mode"
      assert advertiser.allows_clipping_via(:email), "allow for emailing coupon"
      assert advertiser.allows_clipping_via(:txt), "allow for txting coupon"

      get(:public_index, :publisher_id => publisher.to_param)

      assert_select "div.clip_small" do
        assert_select "a.clip_small"
        assert_select "a.email_small"
        assert_select "a.call_small"
        assert_select "a.txt_small"
        assert_select "a.twitter_small"
        assert_select "a.facebook_small"
      end
    end
  end
end
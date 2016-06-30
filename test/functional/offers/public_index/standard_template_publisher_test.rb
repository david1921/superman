require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class OffersController::PublicIndex::StandardTemplatePublisherTest
module OffersController::PublicIndex
  class StandardTemplatePublisherTest < ActionController::TestCase
    tests OffersController

    def test_public_index_buttons_for_standard_template_publisher_with_show_twitter_button_set_to_true
      publisher = publishers(:tucsonweekly)
      publisher.update_attribute(:show_twitter_button, true)
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_tag :a, :attributes => {:class => 'twitter btn_twitter'}
    end

    def test_public_index_buttons_for_standard_template_publisher_with_show_twitter_button_set_to_false
      publisher = publishers(:tucsonweekly)
      publisher.update_attribute(:show_twitter_button, false)
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_no_tag :a, :attributes => {:class => 'twitter btn_twitter'}
    end

    def test_public_index_buttons_for_standard_template_publisher_with_show_facebook_button_set_to_true
      publisher = publishers(:tucsonweekly)
      publisher.update_attribute(:show_facebook_button, true)
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_tag :a, :attributes => {:class => 'facebook btn_facebook'}
    end

    def test_public_index_buttons_for_standard_template_publisher_with_show_facebook_button_set_to_false
      publisher = publishers(:tucsonweekly)
      publisher.update_attribute(:show_facebook_button, false)
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_no_tag :a, :attributes => {:class => 'facebook btn_facebook'}
    end

    def test_public_index_buttons_for_standard_template_publisher_with_show_call_button_set_to_true
      publisher = publishers(:tucsonweekly)
      publisher.update_attribute(:show_call_button, true)
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_tag :a, :attributes => {:class => 'call btn_call'}
    end

    def test_public_index_buttons_for_standard_template_publisher_with_show_call_button_set_to_false
      publisher = publishers(:tucsonweekly)
      publisher.update_attribute(:show_call_button, false)
      publisher.advertisers.create!.offers.create!(:message => "Free yogurt with your taco")
      get(:public_index, :publisher_id => publisher.to_param)
      assert_no_tag :a, :attributes => {:class => 'call btn_call'}
    end

    def test_public_index_standard_publisher_without_custom_layout
      publisher = Factory(:publisher, :name => "New", :theme => "standard", :label => "newpub-1")
      get :public_index, :publisher_id => publisher.to_param
      assert_layout "offers/public_index"
    end
  end
end
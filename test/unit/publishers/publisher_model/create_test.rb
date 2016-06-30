require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::CreateTest
module Publishers
  module PublisherModel
    class CreateTest < ActiveSupport::TestCase
      test "create" do
        publisher = Factory(:publisher, :name => "Yahoo")
        assert_equal "yahoo", publisher.label
        assert publisher.link_to_email?, "link_to_email default"
        assert publisher.link_to_map?, "link_to_map default"
        assert publisher.link_to_website?, "link_to_website default"
        assert !publisher.random_coupon_order?, "random_coupon_order default"
        assert !publisher.send_intro_txt?, "send_intro_txt default"
        assert !publisher.generate_coupon_code?, "generate coupon code default"
        assert !publisher.place_offers_with_group?, "place offers with group default"

        publisher = Factory(:publisher, :name => "Google", :label => " ")
        assert_nil publisher.reload.label, "Blank label should be saved as NULL"

        assert(!Publisher.new.valid?, "Publisher name should be required")
        assert_equal( "solid", publisher.coupon_border_type, "Default border type should be solid." )
        assert( !publisher.show_phone_number, "show_phone_number default" )

        assert !publisher.show_twitter_button, "show_twitter_button default"
        assert !publisher.show_facebook_button, "show_facebook_button default"
        assert !publisher.show_small_icons, "show_small_icons default"
        assert !publisher.allow_gift_certificates, "allow_gift_certificates default"
        assert !publisher.enable_featured_gift_certificate, "enable_featured_gift_certificate default"
        assert !publisher.allow_consumer_show_action, "allow_consumer_show_action"

        assert !publisher.allow_daily_deals, "allow_daily_deals default"

        assert !publisher.enable_search_by_publishing_group, "enable_search_by_publishing_group default"
        assert_nil publisher.default_offer_search_postal_code, "default_offer_search_postal_code"
        assert !publisher.show_zip_code_search_box, "show_zip_code_search_box default"
        assert !publisher.use_production_host_for_facebook_shares, "use_production_host_for_facebook_shares default"
        assert !publisher.enable_side_deal_value_proposition_features, "enable_side_deal_value_proposition_features default"
        assert !publisher.enable_offer_headline, "enable_offer_headline default"
        assert !publisher.enable_daily_deal_variations, "enable_daily_deal_variations default"
      end
    end
  end
end

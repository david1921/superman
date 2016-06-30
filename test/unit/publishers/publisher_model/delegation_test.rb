require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::DelegationTest
module Publishers
  module PublisherModel
    class DelegationTest < ActiveSupport::TestCase

      context "publisher#custom_consumer_password_reset_url" do

        should "use when set" do
          p = Factory.build(:publisher, :custom_consumer_password_reset_url => "http://www.yahoo.com")
          assert_equal "http://www.yahoo.com", p.custom_consumer_password_reset_url
        end

        should "delegate to publishing_group when not set" do
          pg = Factory.build(:publishing_group, :custom_consumer_password_reset_url => "http://www.google.com")
          p = Factory.build(:publisher, :publishing_group => pg)
          assert_equal "http://www.google.com", p.custom_consumer_password_reset_url
        end

        should "return nil if there's no publishing_group nor publisher url set" do
          p = Factory.build(:publisher, :publishing_group => nil)
          assert_nil p.custom_consumer_password_reset_url
        end

      end

      context "publisher#allow_consumer_show_action?" do

        should "use when set on publisher" do
          p = Factory.build(:publisher, :allow_consumer_show_action => true)
          assert p.allow_consumer_show_action?
        end

        should "use publisher group if set to true, but false on publisher" do
          pg = Factory.build(:publishing_group, :allow_consumer_show_action => true)
          p  = Factory.build(:publisher, :publishing_group => pg)
          assert p.allow_consumer_show_action?
        end

        should "use publisher if no publishing group" do
          p = Factory.build(:publisher)
          assert !p.allow_consumer_show_action?
        end
      end
    
      context "publisher#daily_deals_available_for_syndication_by_default_override" do
        setup do
          @publishing_group = Factory(:publishing_group)
          @publisher = Factory(:publisher, :publishing_group => @publishing_group)
        end
        
        should "be false by default" do
          assert !@publisher.daily_deals_available_for_syndication_by_default_override?, "Should be false by default since it's not set and publishing group is false"
        end
        
        should "be true when not set and publishing group is true" do
          assert_nil @publisher.read_attribute(:daily_deals_available_for_syndication_by_default_override)
          @publishing_group.update_attribute(:daily_deals_available_for_syndication_by_default, true)
          assert @publisher.daily_deals_available_for_syndication_by_default_override?, "Should be true because it's not set and publishing group is true"
        end
        
        should "be false when its set to false and publishing group is true" do
          @publishing_group.update_attribute(:daily_deals_available_for_syndication_by_default, true)
          @publisher.update_attribute(:daily_deals_available_for_syndication_by_default_override, false)
          assert !@publisher.daily_deals_available_for_syndication_by_default_override?, "Should be false because set to false and publishing group is true"
        end
        
        should "be true when its set to true and publishing group is false" do
          @publisher.update_attribute(:daily_deals_available_for_syndication_by_default_override, true)
          assert @publisher.daily_deals_available_for_syndication_by_default_override?, "Should be true because set to true and publishing group is false"
        end
      end
    
      context "enable_daily_deal_variations?" do

        should "use publisher value if not nil" do
          publisher = Factory(:publisher, :enable_daily_deal_variations => true)
          assert_equal true, publisher.enable_daily_deal_variations
        end

        should "delegate to publishing_group if publisher.enable_daily_deal_variations is false" do
          publishing_group = Factory(:publishing_group, :enable_daily_deal_variations => true)
          publisher = Factory(:publisher, :publishing_group => publishing_group, :enable_daily_deal_variations => false)
          assert_equal true, publisher.enable_daily_deal_variations?
        end

        should "delegate to publishing_group if is nil" do
          publishing_group = Factory(:publishing_group, :enable_daily_deal_variations => true)
          publisher = Factory(:publisher, :publishing_group => publishing_group, :enable_daily_deal_variations => nil)
          assert_equal true, publisher.enable_daily_deal_variations?
        end

      end

      context "publisher#send_litle_campaign?" do
        setup do
          @publishing_group = Factory(:publishing_group)
          @publisher = Factory(:publisher, :publishing_group => @publishing_group)
        end

        should "be true if both publisher and group are true" do
          assert_equal true, @publisher.send_litle_campaign?
        end

        should "be true if publishing_group is true and publisher is false" do
          @publisher.update_attributes(:send_litle_campaign => false)
          assert_equal true, @publisher.send_litle_campaign?
        end

        should "be true if publishing_group is false and publisher is true" do
          @publisher.update_attributes(:send_litle_campaign => true)
          @publishing_group.update_attributes(:send_litle_campaign => false)

          assert_equal true, @publisher.send_litle_campaign?
        end

        should "be false if both publisher and group are false" do
          @publisher.update_attributes(:send_litle_campaign => false)
          @publishing_group.update_attributes(:send_litle_campaign => false)

          assert_equal false, @publisher.send_litle_campaign?
        end

      end

      context "delegation of use_vault" do

        should "default to false if no publishing group" do
          publisher = Factory(:publisher, :publishing_group => nil)
          assert !publisher.use_vault?
          assert !publisher.use_vault
        end

        should "be false if false for publishing group" do
          publishing_group = Factory(:publishing_group, :use_vault => false)
          publisher = Factory(:publisher, :publishing_group => publishing_group)
          assert !publisher.use_vault?
          assert !publisher.use_vault
        end

        should "be true if true for publishing group" do
          publishing_group = Factory(:publishing_group, :use_vault => true)
          publisher = Factory(:publisher, :publishing_group => publishing_group)
          assert publisher.use_vault?
          assert publisher.use_vault
        end

      end

    end
  end
end



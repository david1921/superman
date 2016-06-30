require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::VariationsTest

class Syndication::VariationsTest < ActiveSupport::TestCase

  context "source deal" do

    setup do
      @source_deal = Factory(:daily_deal_for_syndication)
      @source_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

      @variation_1 = Factory(:daily_deal_variation, :daily_deal => @source_deal)
      @variation_2 = Factory(:daily_deal_variation, :daily_deal => @source_deal)

    end

    context "without any distributed deals" do

      should "be able to add a new variation" do
        new_variation = @source_deal.daily_deal_variations.create(:value_proposition => "I am a new variation", :price => 30.00, :value => 60.00)
        assert new_variation.valid?, "new variation should be valid"
        assert_equal 3, @source_deal.reload.daily_deal_variations.size, "source deal should have 3 variations now"
      end

      should "be able to update an existing variation" do
        existing_variation = @source_deal.daily_deal_variations.first
        existing_variation.update_attributes(:value_proposition => "I AM NOW CHANGED")
        assert existing_variation.valid?
        assert_equal "I AM NOW CHANGED", existing_variation.value_proposition 
      end

      should "be able to remove an existing variation" do
        existing_variation = @source_deal.daily_deal_variations.first
        assert existing_variation.destroy
        assert_equal 1, @source_deal.reload.daily_deal_variations.size, "source deal should only have 1 variation now"
      end

    end

    context "with a distributed deal" do

      setup do
        @distributed_publisher = Factory(:publisher, :enable_daily_deal_variations => true )
        syndicate( @source_deal, @distributed_publisher )
        @source_deal.reload
      end

      should "NOT be able to add a new variation" do
        new_variation = @source_deal.daily_deal_variations.create(:value_proposition => "New Variation", :price => 30.00, :value => 60.00)      
        assert !new_variation.valid?, "should not be able to add new variation to source deal once it has been syndicated"
      end

      should "NOT be able to update an existing variation" do
        existing_variation = @source_deal.daily_deal_variations.first
        existing_variation.update_attributes( :value_proposition => "I AM NOW CHANGED" )
        assert !existing_variation.valid?, "existing variation should be updateable if source deal has been syndicated"
      end

      should "NOT be able to remove an existing variation" do
        existing_variation = @source_deal.daily_deal_variations.first
        assert !existing_variation.destroy
      end

    end

  end

  context "distributed deal" do

    setup do
      source_deal = Factory(:daily_deal_for_syndication)
      source_deal.publisher.update_attribute(:enable_daily_deal_variations, true)

      @variation_1 = Factory(:daily_deal_variation, :daily_deal => source_deal)
      @variation_2 = Factory(:daily_deal_variation, :daily_deal => source_deal)

      @disbributed_publisher = Factory(:publisher, :enable_daily_deal_variations => true)
      @distributed_deal = syndicate( source_deal, @disbributed_publisher )
    end

    should "NOT be able to add a new variation" do
      new_variation = @distributed_deal.daily_deal_variations.create(:value_proposition => "New Variation", :price => 30.00, :value => 60.00)      
      assert !new_variation.valid?, "new variation should not be valid"
    end

    should "NOT be able to update an existing variation" do
      existing_variation = @distributed_deal.daily_deal_variations.first
      existing_variation.update_attributes(:value_proposition => "I HAVE BEEN UPDATED")
      assert !existing_variation.valid?, "updating existing variation should not be valid"
    end

    should "NOT be able to remove an existing variation" do
      existing_variation = @distributed_deal.daily_deal_variations.first
      assert !existing_variation.destroy
    end

  end

end

require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealVariationsTest < ActiveSupport::TestCase

  context "create" do
    
    setup do
      @daily_deal = Factory(:daily_deal)
    end

    should "have no daily deal variations to begin with" do
      assert @daily_deal.daily_deal_variations.empty?, "should have no variations"
    end

    context "with a publisher allowed to have daily deal variations" do

      setup do
        @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
      end

      context "with just one variation" do

        should "be able to create a new variation" do
          @daily_deal.daily_deal_variations.create!(Factory.attributes_for(:daily_deal_variation, :value_proposition => "I am a variation", :value => 15.00, :price => 7.00))
          @daily_deal.reload
          assert_equal 1, @daily_deal.daily_deal_variations.size
          assert @daily_deal.has_variations?, "should have variations"
          variation = @daily_deal.daily_deal_variations.first
          assert_equal "I am a variation", variation.value_proposition
          assert_equal 15.00, variation.value
          assert_equal 7.00, variation.price
          assert_equal "DDV-#{variation.id}", variation.listing
        end

      end

      context "with multiple variations with no soft deleted variations" do

        setup do
          @variation_1 = @daily_deal.daily_deal_variations.create!(Factory.attributes_for(:daily_deal_variation, :value_proposition => "I am variation 1", :value => 15.00, :price => 7.00))
          @variation_2 = @daily_deal.daily_deal_variations.create!(Factory.attributes_for(:daily_deal_variation, :value_proposition => "I am variation 2", :value => 7.00, :price => 3.00))
          @variation_3 = @daily_deal.daily_deal_variations.create!(Factory.attributes_for(:daily_deal_variation, :value_proposition => "I am variation 3", :value => 30.00, :price => 15.00))
          @daily_deal.reload
        end

        should "have 3 variations" do
          assert_equal 3, @daily_deal.daily_deal_variations.size
        end

        should "setup @variation_1" do
          @variation_1.reload
          assert @daily_deal.daily_deal_variations.include?( @variation_1 )
          assert_equal 1, @variation_1.daily_deal_sequence_id
          assert_equal "I am variation 1", @variation_1.value_proposition
        end

        should "setup @variation_2" do
          @variation_2.reload
          assert @daily_deal.daily_deal_variations.include?( @variation_2 )
          assert_equal 2, @variation_2.daily_deal_sequence_id
          assert_equal "I am variation 2", @variation_2.value_proposition
        end

        should "setup @variation_3" do
          @variation_3.reload
          assert @daily_deal.daily_deal_variations.include?( @variation_3 )
          assert_equal 3, @variation_3.daily_deal_sequence_id
          assert_equal "I am variation 3", @variation_3.value_proposition
        end        

        should "return in order of price" do
          assert_equal [@variation_2, @variation_1, @variation_3], @daily_deal.daily_deal_variations
        end
        
      end

      context "with deleted variations" do

        setup do
          @variation_1 = @daily_deal.daily_deal_variations.create!(
            Factory.attributes_for(:daily_deal_variation, :value_proposition => "I am variation 1", :value => 15.00, :price => 7.00)
          )
          @variation_2 = @daily_deal.daily_deal_variations.create!(
            Factory.attributes_for(:daily_deal_variation, :value_proposition => "I am variation 2", :value => 7.00, :price => 3.00)
          )
          @variation_3 = @daily_deal.daily_deal_variations.create!(
            Factory.attributes_for(:daily_deal_variation, :value_proposition => "I am variation 3", :value => 30.00, :price => 15.00, :deleted_at => 2.days.ago)
          )
          @daily_deal.reload
        end

        should "setup @variation_1" do
          @variation_1.reload
          assert @daily_deal.daily_deal_variations.include?( @variation_1 )
          assert_equal 1, @variation_1.daily_deal_sequence_id
          assert_equal "I am variation 1", @variation_1.value_proposition
        end

        should "setup @variation_2" do
          @variation_2.reload
          assert @daily_deal.daily_deal_variations.include?( @variation_2 )
          assert_equal 2, @variation_2.daily_deal_sequence_id
          assert_equal "I am variation 2", @variation_2.value_proposition
        end

        should "setup @variation_3, and should not be include in daily deal variations" do
          @variation_3.reload
          assert !@daily_deal.daily_deal_variations.include?( @variation_3 )
          assert_equal 3, @variation_3.daily_deal_sequence_id
          assert_equal "I am variation 3", @variation_3.value_proposition
        end

        should "not return deleted variations when daily_deal_variations is called" do
          assert_equal 2, @daily_deal.daily_deal_variations.size, "should only return 2 variations"
          assert !@daily_deal.daily_deal_variations.include?( @variation_3 ), "should not include vairation"
        end

        should "return deleted variations when daily_deal_variations_with_deleted is called" do
          assert_equal 3, @daily_deal.daily_deal_variations_with_deleted.size, "should return all 3 variations"
          assert @daily_deal.daily_deal_variations_with_deleted.include?( @variation_3 )
        end

        should "take soft deleted variations into account when generating a new daily deal sequence id" do
          new_variation = @daily_deal.daily_deal_variations.create!(
            Factory.attributes_for(:daily_deal_variation, :value_proposition => "I am a NEW variation", :value => 45.00, :price => 30.00)
          )
          @daily_deal.reload
          assert_equal 4, new_variation.daily_deal_sequence_id
          assert_equal 3, @daily_deal.daily_deal_variations.size
          assert_equal 4, @daily_deal.daily_deal_variations_with_deleted.size
        end

      end



    end

    context "with a publisher NOT allowed to have daily deal variations" do

      setup do
        @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, false)
      end

      should "assign an error to the daily deal variation, that the publisher is not allowed to make a variation" do
        variation = @daily_deal.daily_deal_variations.build(:value_proposition => "I am a variation", :value => 15.00, :price => 7.00)
        assert !variation.valid?, "variation should not be valid"
      end
    end


  end

  context "sold out" do
    setup do
      @daily_deal = Factory(:daily_deal)
      @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
      @variation = @daily_deal.daily_deal_variations.create!(Factory.attributes_for(:daily_deal_variation, :value_proposition => "I am a variation", :value => 15.00, :price => 7.00))
    end

    should "not be sold out" do
      assert_equal nil,  @variation.sold_out_at
    end

    should "be have a sold out timestamp" do
      Timecop.freeze(now = Time.now) do
        @variation.sold_out!(true)
        assert_equal now, @variation.sold_out_at
      end
    end

    should "not update the sold out timestamp" do
      Timecop.freeze(now = Time.now) do
        @variation.sold_out!(true)
        assert_equal now, @variation.sold_out_at
      end
      @variation.sold_out!(true)
      assert_equal now, @variation.sold_out_at
    end

  end

  context "update" do

    setup do
      @daily_deal = Factory(:daily_deal, :start_at => 10.days.ago, :hide_at => 3.days.from_now)
      @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
      @variation  = Factory(:daily_deal_variation, :daily_deal => @daily_deal)
    end

    should "be able to update variation if deal hasn't ended" do
      assert !@daily_deal.over?, "deal should not be over"
      assert @variation.update_attributes(:value_proposition => "This is a new value prop", :voucher_headline => "This is a new voucher headline")
    end

    should "not be able to update variation if deal has ended" do
      @daily_deal.update_attribute(:hide_at, 1.day.ago)
      assert @daily_deal.over?, "deal should be over"
      assert !@variation.update_attributes(:value_proposition => "This is a new value prop")
    end

  end

  context "lowest_price" do

    setup do
      @daily_deal = Factory(:daily_deal)
      @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
      Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 60.00, :price => 30.00 )
      Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 30.00, :price => 15.00 )
    end

    should "return the lowest price amongst all the daily deal variations" do
      assert_equal 15.00, @daily_deal.lowest_price
    end

  
  end

  context "number_sold" do

    setup do
      @daily_deal = Factory(:daily_deal)
      @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
      @variation_1 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 60.00, :price => 30.00 )
      @variation_2 = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :value => 30.00, :price => 15.00 )
    end

    should "not have any number sold when no daily deal variations have purchases" do
      assert_equal 0, @daily_deal.number_sold
    end

    context "with justing pending purchases" do

      setup do
        Factory(:pending_daily_deal_purchase, :daily_deal => @daily_deal, :daily_deal_variation => @variation_1)
      end

      should "not have any number sold with just one pending purchase" do
        assert_equal 0, @daily_deal.number_sold
      end

    end

    context "with a captured purchase on multiple purchases" do

      setup do
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :daily_deal_variation => @variation_1 )
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :daily_deal_variation => @variation_2, :quantity => 2 )
      end

      should "have 3 for number sold" do
        assert_equal 3, @daily_deal.number_sold
      end

    end

  end

end

require File.dirname(__FILE__) + "/../test_helper"

class DailyDealVariationTest < ActiveSupport::TestCase

  context "create" do

    context "with daily deal" do

      setup do
        @daily_deal = Factory(:daily_deal, :quantity => 20, :min_quantity => 1, :max_quantity => 3)
      end

      context "variation methods" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
          @variation = DailyDealVariation.create(
                                          :daily_deal => @daily_deal,
                                          :value_proposition => "3 day trip to somewhere",
                                          :value => 1500.00, :price => 780.00,
                                          :value_proposition_subhead => "this is the subhead",
                                          :voucher_headline => "this is voucher headline",
                                          :terms => "* term 1\n* term 2",
                                          :quantity => 10
                                          )
        end

        should "forward #ended? to DailyDeal#ended?" do
          @daily_deal.stubs(:ended?).once

          @variation.ended?
        end

      end

      context "with a publisher that is enabled for daily deal variations" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
        end

        should "be able to set value proposition, value_proposition_subhead, value, and price" do
          variation = DailyDealVariation.create(
                                          :daily_deal => @daily_deal,
                                          :value_proposition => "3 day trip to somewhere",
                                          :value => 1500.00, :price => 780.00,
                                          :value_proposition_subhead => "this is the subhead",
                                          :voucher_headline => "this is voucher headline",
                                          :terms => "* term 1\n* term 2",
                                          :quantity => 10,
                                          :min_quantity => 1,
                                          :max_quantity => 5
                                          )
          assert variation.valid?
          assert_equal "3 day trip to somewhere", variation.value_proposition
          assert_equal "this is the subhead", variation.value_proposition_subhead
          assert_equal "this is voucher headline", variation.voucher_headline
          assert_equal "<ul>\n\t<li>term 1</li>\n\t<li>term 2</li>\n</ul>", variation.terms
          assert_equal 1500.00, variation.value
          assert_equal 780.00, variation.price
          assert_equal 10, variation.quantity
          assert_equal 1, variation.min_quantity
          assert_equal 5, variation.max_quantity
          assert_equal "DDV-#{variation.id}", variation.listing
        end

        should "default min_quantity to DailyDeal::MIN_QUANTITY and max_quantity to DailyDeal::MAX_QUANTITY" do
          variation = DailyDealVariation.create(
                                          :daily_deal => @daily_deal,
                                          :value_proposition => "3 day trip to somewhere",
                                          :value => 1500.00, :price => 780.00,
                                          :value_proposition_subhead => "this is the subhead",
                                          :voucher_headline => "this is voucher headline",
                                          :terms => "* term 1\n* term 2",
                                          :quantity => 10
                                          )
          assert variation.valid?, "should be valid"
          assert_equal DailyDeal::MIN_QUANTITY_DEFAULT, variation.min_quantity, "should set the default min quantity to the daily deal default min quantity"
          assert_equal DailyDeal::MAX_QUANTITY_DEFAULT, variation.max_quantity
        end

        should "not be able to have a max quantity less than min quantity" do
          variation = DailyDealVariation.create(
                                          :daily_deal => @daily_deal,
                                          :value_proposition => "3 day trip to somewhere",
                                          :value => 1500.00, :price => 780.00,
                                          :value_proposition_subhead => "this is the subhead",
                                          :voucher_headline => "this is voucher headline",
                                          :terms => "* term 1\n* term 2",
                                          :quantity => 10,
                                          :min_quantity => 3,
                                          :max_quantity => 2
            )
          assert !variation.valid?, "should not be valid"
          assert variation.errors.on(:max_quantity)
        end

        should "not be able to have min quantity more than actual quantity" do
          variation = DailyDealVariation.create(
                                          :daily_deal => @daily_deal,
                                          :value_proposition => "3 day trip to somewhere",
                                          :value => 1500.00, :price => 780.00,
                                          :value_proposition_subhead => "this is the subhead",
                                          :voucher_headline => "this is voucher headline",
                                          :terms => "* term 1\n* term 2",
                                          :quantity => 2,
                                          :min_quantity => 3,
                                          :max_quantity => 4
            )
          assert !variation.valid?, "should not be valid"
          assert variation.errors.on(:min_quantity)
        end

        context "removing variations" do
          setup do
            @variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal)
          end

          should "not allow a variation to be removed if it is already running" do
            Timecop.freeze(@variation.daily_deal.start_at + 1.second) do
              assert_raise RuntimeError, "Can't remove variation because it has already started xx." do
                @variation.delete!
              end
            end
          end

          should "not allow a variation to be removed if it has already sold" do
            daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => @variation.daily_deal, :daily_deal_variation => @variation)
            puts daily_deal_purchase.errors.full_messages
            assert_raise RuntimeError, "Can't remove variation because the deal has sales.XX" do
              @variation.delete!
            end
          end

          should "allow a variation to be removed if it has not started running and has no sales" do
            @variation.delete!

            assert @variation.deleted?
            assert @daily_deal.daily_deal_variations_with_deleted.include?(@variation)
          end
        end
      end

      context "with a publisher that is NOT enabled for daily deal variations" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, false)
        end

        should "assign an validation error" do
          variation = DailyDealVariation.create(:daily_deal => @daily_deal, :value_proposition => "3 day trip to somewhere", :value => 1500.00, :price => 780.00)
          assert !variation.valid?, "should not be valid"
        end

      end
    end


  end

end

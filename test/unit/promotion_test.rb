require File.dirname(__FILE__) + "/../test_helper"

class PromotionTest < ActiveSupport::TestCase

  should have_many(:discounts)

  context "validation" do
    setup do
      now = Time.zone.now
      @valid_attributes = {
          :publishing_group_id => Factory(:publishing_group).id,
          :details => "Buy something during this promotion and you'll get a code to apply on your next purchase",
          :start_at => now - 1.week,
          :end_at => now + 1.week,
          :codes_expire_at => now + 1.month,
          :code_prefix => "ECM123",
          :amount => "10.00"
      }
    end

    should "consider the promotion valid with valid attributes" do
      promotion = Promotion.new(@valid_attributes)
      assert_equal true, promotion.valid?
    end

    should "consider the promotion invalid when there is no publishing group" do
      @valid_attributes[:publishing_group_id] = nil
      promotion = Promotion.new(@valid_attributes)
      assert promotion.invalid?
    end

    should "consider the promotion invalid when there is no start at" do
      @valid_attributes[:start_at] = nil
      promotion = Promotion.new(@valid_attributes)
      assert promotion.invalid?
    end

    should "consider the promotion invalid when there is no end at" do
      @valid_attributes[:end_at] = nil
      promotion = Promotion.new(@valid_attributes)
      assert promotion.invalid?
    end

    should "consider the promotion invalid when there is no expiration date for the codes" do
      @valid_attributes[:codes_expire_at] = nil
      promotion = Promotion.new(@valid_attributes)
      assert promotion.invalid?
    end

    should "consider the promotion invalid when there is no amount" do
      @valid_attributes[:amount] = nil
      promotion = Promotion.new(@valid_attributes)
      assert promotion.invalid?
    end

    should "consider the promotion invalid when the amount is not a number" do
      @valid_attributes[:amount] = "abcde"
      promotion = Promotion.new(@valid_attributes)
      assert promotion.invalid?
    end

    should "consider the promotion invalid when the amount is not greater than zero" do
      @valid_attributes[:amount] = 0
      promotion = Promotion.new(@valid_attributes)
      assert promotion.invalid?
    end

    should "consider the promotion invalid when the end date is after the start date" do
      @valid_attributes[:start_at] = 1.day.from_now
      @valid_attributes[:end_at] = 1.day.ago
      promotion = Promotion.new(@valid_attributes)
      assert promotion.invalid?
    end

    should "consider the promotion invalid when the expire date is before the end date" do
      @valid_attributes[:end_at] = 1.day.from_now
      @valid_attributes[:codes_expire_at] = 1.day.ago
      promotion = Promotion.new(@valid_attributes)
      assert promotion.invalid?
    end

  end

  context "#create_discount_for_purchase" do
    setup do
      @purchase = Factory(:daily_deal_purchase)
      @publisher = @purchase.daily_deal.publisher
      @promotion = Factory(:promotion, :publishing_group => @publisher.publishing_group)
    end

    should "create a discount" do
      assert !Discount.find_by_daily_deal_purchase_id(@purchase.id)
      Promotion.any_instance.expects(:generate_discount_code).returns("ABC123")
      Timecop.freeze(Time.zone.now) do
        @promotion.create_discount_for_purchase(@purchase)
        discount = Discount.find_by_daily_deal_purchase_id(@purchase.id)
        assert discount
        assert_equal @promotion.amount, discount.amount 
        assert_equal @purchase.publisher, discount.publisher
        assert_equal @promotion.codes_expire_at.to_i, discount.last_usable_at.to_i
        assert_equal Time.zone.now.to_i, discount.first_usable_at.to_i
        assert discount.usable_at_checkout
        assert discount.usable_only_once
        assert_equal "ABC123", discount.code
      end
    end

  end

  context "#generate_discount_code" do
    setup do
      @promotion = Factory(:promotion, :code_prefix => "ABC")
    end

    should "generate a random code with self.code_prefix as a prefix" do
      code = @promotion.generate_discount_code
      assert_equal "ABC", code[0..2]
      assert_equal 10, code.size
    end
  end

  context "#active" do
    setup do
      Promotion.delete_all
      @promotion = Factory(:promotion, :start_at => 3.days.ago, :end_at => 2.days.from_now)
      @promotion1 = Factory(:promotion, :start_at => 3.days.from_now, :end_at => 4.days.from_now)
    end

    should "only return promotions currently running" do
      promotions = Promotion.active
      assert_equal 1, promotions.size
      assert_equal @promotion, promotions.first
    end
  end
end

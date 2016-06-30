require File.dirname(__FILE__) + "/../../models_helper"

class BaseDailyDealPurchases::CoreTest < Test::Unit::TestCase
  def setup
    @obj = Object.new.extend(BaseDailyDealPurchases::Core)
  end

  context "#consumer_name" do
    context "with consumer" do
      should "return the consumer's name" do
        consumer = mock('consumer')
        name = 'Joe Shmoe'
        consumer.stubs(:name).returns(name)
        @obj.stubs(:consumer).returns(consumer)
        assert_equal name, @obj.consumer_name
      end
    end

    context "without consumer" do
      should "return nil" do
        @obj.stubs(:consumer)
        assert_nil @obj.consumer_name
      end
    end
  end

  context "#consumer_email" do
    context "with consumer" do
      should "return the consumer's email" do
        consumer = mock('consumer')
        email = 'joe@schmoe.com'
        consumer.stubs(:email).returns(email)
        @obj.stubs(:consumer).returns(consumer)
        assert_equal email, @obj.consumer_email
      end
    end

    context "without consumer" do
      should "return nil" do
        @obj.stubs(:consumer)
        assert_nil @obj.consumer_email
      end
    end
  end

  context "#travelsavers?" do
    should "return true for travelsavers purchases" do
      @obj.stubs(:pay_using?).with(:travelsavers).returns(true)
      assert @obj.travelsavers?
    end

    should "return false for non-travelsavers purchases" do
      @obj.stubs(:pay_using?).with(:travelsavers).returns(false)
      assert !@obj.travelsavers?
    end
  end

  context "#creates_payment?" do
    should "return true when purchase is not travelsavers" do
      @obj.stubs(:travelsavers?).returns(false)
      assert @obj.creates_payment?
    end

    should "return false when purchase is travelsavers" do
      @obj.stubs(:travelsavers?).returns(true)
      assert !@obj.creates_payment?
    end
  end

end

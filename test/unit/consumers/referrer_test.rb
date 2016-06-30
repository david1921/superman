require File.dirname(__FILE__) + "/../../test_helper"

class Consumers::ReferrerTest < ActiveSupport::TestCase

  context "#referring_consumer" do
    setup do
      @consumer = Factory(:consumer)
      assert @consumer.referrer_code
      @referred_consumer = Factory(:consumer, :referral_code => @consumer.referrer_code)
      assert_equal @consumer.referrer_code, @referred_consumer.referral_code
    end

    should "return the consumer that referred the consumer" do
      assert_equal @consumer.id, @referred_consumer.referring_consumer.id
    end

    should "return nil if called on a consumer that was not referred" do
      consumer = Factory(:consumer, :referral_code => nil)
      assert_equal nil, consumer.referring_consumer
    end

  end
end

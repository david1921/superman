require File.dirname(__FILE__) + "/../../models_helper"

class DailyDealCertificates::StatusTest < Test::Unit::TestCase
  def setup
    @obj = Object.new.extend(DailyDealCertificates::Status)
  end
  
  context "#set_status!" do
    should "call #redeem! when 'redeemed'" do
      @obj.expects('redeem!')
      @obj.set_status!('redeemed')
    end

    should "call #void! when 'voided'" do
      @obj.expects('void!')
      @obj.set_status!('voided')
    end

    should "call #refund! when 'refunded'" do
      @obj.expects('void!')
      @obj.set_status!('voided')
    end

    should "call #activate! when 'active'" do
      @obj.expects('activate!')
      @obj.set_status!('active')
    end

    should "raise an exception when no redeemed, refunded or voided" do
      assert_raise RuntimeError do
        @obj.set_status!('invalid status')
      end
    end
  end
end
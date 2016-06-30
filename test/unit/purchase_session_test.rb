require File.dirname(__FILE__) + "/../test_helper"

class PurchaseSessionTestFake
  include PurchaseSession
  def session
    @session ||= Hash.new
  end
  def session=(item)
    @session << item
  end
end

class PurchaseSessionTests < ActiveSupport::TestCase

  context 'when a purchase session was set with a certain token' do
    TOKEN = 'foobar'
    setup do
      @target = PurchaseSessionTestFake.new
      @target.set_purchase_session TOKEN
    end
    should 'be authorized to purchase with the same token' do
      assert @target.has_matching_purchase_session?(TOKEN)
    end
    should 'not be authorized to purchase with a different token' do
      assert !@target.has_matching_purchase_session?('wrong')
    end
    context 'and then the purchase session was killed' do
      setup do
        @target.kill_purchase_session!
      end
      should 'not be authorized to purchase with the same token' do
        assert !@target.has_matching_purchase_session?(TOKEN)
      end
    end
  end
  context 'when a purchase session was set with a nil token' do
    setup do
      @target = PurchaseSessionTestFake.new
      @target.set_purchase_session nil
    end
    should 'not set purchase session' do
      assert @target.session.none?
    end
  end
  context 'when a purchase session was set with a blank token' do
    setup do
      @target = PurchaseSessionTestFake.new
      @target.set_purchase_session ''
    end
    should 'not set purchase session' do
      assert @target.session.none?
    end
  end

end
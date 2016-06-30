require File.dirname(__FILE__) + "/../test_helper"

class DailyDealSessionsController_PurchaseSessionTests < ActionController::TestCase
  tests DailyDealSessionsController
  context 'when a purchase session exists and then login' do
    setup do
      session[PurchaseSession::PURCHASE_SESSION_TOKEN_KEY] = 'foobar'
      publisher = Factory :publisher
      consumer = Factory :consumer, :publisher => publisher
      post :create, :publisher_id => publisher.to_param, 
          :session => { :email => consumer.email, :password => 'monkey' }
    end
    should 'clear the purchase session' do
      assert_nil session[PurchaseSession::PURCHASE_SESSION_TOKEN_KEY]
    end
  end

end
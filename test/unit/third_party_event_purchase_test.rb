require File.dirname(__FILE__) + "/../test_helper"

class ThirdPartyEventPurchaseTest < ActiveSupport::TestCase
  context "base" do 
    setup do
      @event_purchase = create_event_purchase
    end
    should "create ThirdPartyEventPurchase" do
      assert_difference "ThirdPartyEventPurchase.count" do
        purchase_event = create_event_purchase
        assert !purchase_event.new_record?
      end
    end
    should "require price, quantity, deal id and transaction_id" do
      assert_bad_value ThirdPartyEventPurchase, 'price', nil
      assert_bad_value ThirdPartyEventPurchase, 'price', "one"
      assert_good_value ThirdPartyEventPurchase, 'price', 5.50
      assert_good_value ThirdPartyEventPurchase, 'price', 15

      assert_bad_value ThirdPartyEventPurchase, 'quantity', nil
      assert_bad_value ThirdPartyEventPurchase, 'quantity', "one"
      assert_bad_value ThirdPartyEventPurchase, 'quantity', 0
      assert_good_value ThirdPartyEventPurchase, 'quantity', 5
      
      assert_bad_value ThirdPartyEventPurchase, 'product_id', nil
      assert_good_value ThirdPartyEventPurchase, 'product_id', 231311
      
      assert_good_value  ThirdPartyEventPurchase, 'transaction_id', "7sd89as789das7"
    end
    
  end
  
  def create_event_purchase(options = {}, event_options = {})
   advertiser = Factory(:advertiser)
   deal = Factory(:daily_deal, :advertiser => advertiser)
   e_attrs = {
     :action => 'purchase',
     :visitor => Factory(:consumer),
     :third_party => advertiser,
     :target => deal
   }.merge(event_options)
   event = ThirdPartyEvent.new(e_attrs)
   event.save
   attrs = {
    :third_party_event => event,
    :product_id => deal.id,
    :price => deal.price,
    :quantity => 1,
    :transaction_id => "2347834"
   }.merge(options)
   record = ThirdPartyEventPurchase.new(attrs)
   record.save
   
   record
  end

end

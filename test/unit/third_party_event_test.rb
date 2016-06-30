require File.dirname(__FILE__) + "/../test_helper"

class ThirdPartyEventTest < ActiveSupport::TestCase
  context "base" do
    setup do
      @event = create_event
    end
    should "validate attributes" do
      assert_bad_value ThirdPartyEvent, 'action', nil
      assert_bad_value ThirdPartyEvent, 'action', "takeOff"
      ThirdPartyEvent::VALID_ACTIONS.each do |name|
        assert_good_value ThirdPartyEvent, 'action', name
      end
      assert_bad_value ThirdPartyEvent, 'session_id', nil

    end
    should "standardize action name, boolean helpers" do
      @event.action = 'lANDing'
      assert @event.action, 'landing'
    end
    should "create ThirdPartyEvent" do
      assert_difference "ThirdPartyEvent.count" do
        @event = create_event
        # assert !@event.new_record?
        assert @event.errors.empty?, @event.errors.full_messages.join("|")
      end
    end
    should "have helper boolean methods" do
      @event.action = 'purchase'
      @event.save
      assert @event.purchase?
      assert !@event.landing?
      
      @event.action = 'redirect'
      @event.save
      assert @event.redirect?
      assert !@event.landing?
      
      @event.action = 'landing'
      @event.save
      assert @event.landing?
      assert !@event.purchase?
    end
  end
  context "minimal" do
    should "create ThirdPartyEvent" do
      assert_difference "ThirdPartyEvent.count" do
        @event = create_minimal_event
        assert !@event.new_record?
        assert @event.errors.empty?, @event.errors.full_messages.join("|")  
      end
    end
  end
    
  def create_event(options = {})
    advertiser = Factory(:advertiser)
    attrs = {
      :action => 'landing',
      :session_id => "ohhai7d98as7d98as7d89as7",
      :visitor => Factory(:consumer),
      :third_party => advertiser,
      :target => Factory(:daily_deal, :advertiser => advertiser)
    }.merge(options)
    
    record = ThirdPartyEvent.new(attrs)
    record.save
    record
  end
  def create_minimal_event
    record = ThirdPartyEvent.new({:action => "landing", :session_id => "coffe017d98as7d89as7"})
    record.save
    record
  end
    
end
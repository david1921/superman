require File.dirname(__FILE__) + "/../../models_helper"

class TravelsaversBookings::StateMachineTest < Test::Unit::TestCase
  def setup
    @state_machine = Object.new.extend(TravelsaversBookings::StateMachine::InstanceMethods)
  end

  context "#capture_successful_booking_and_failed_payment" do
    should "notify about payment failure" do
      @state_machine.stubs(:set_payment_status_and_executed_at!)
      @state_machine.expects(:notify_about_payment_failure!)
      @state_machine.send(:capture_successful_booking_and_failed_payment)
    end
  end

  context "#capture_failed_booking_and_failed_payment" do
    should "notify about booking failure" do
      @state_machine.stubs(:daily_deal_purchase).returns(stub_everything)
      @state_machine.stubs(:set_payment_status_and_executed_at!)
      @state_machine.expects(:notify_about_booking_failure!)
      @state_machine.send(:capture_failed_booking_and_failed_payment)
    end
  end
end

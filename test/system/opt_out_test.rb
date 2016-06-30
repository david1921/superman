#!/usr/bin/env script/runner

# Run script from RAILS_ROOT: ./test/system/opt_out_test.rb -e nightly 100
#
# -e     : Rails environment. Defaults to development
# number : number of opt-outs. Defaults to 10
#
# development environment doesn't cache, so it's slow unless you modify config/environments/development.rb

require "test/system/system_test"

class OptOutTest < SystemTest

  def run
    at_exit { stop_daemons }

    setup_data
    create_visitors
    start_gateway
    txt_gateway.delete_all_messages
    visitors.each { |visitor| visitor.send_opt_out_txt }
    start_daemons
    wait_for_outbound_messages
    assert_messages
    print_performance_numbers
    puts "Done."
  end

  def wait_for_outbound_messages
    p "wait_for_outbound_messages"
    start_time = Time.now
    elapsed_time = 0
    received_txt_count = 0
    while (elapsed_time < 180 && received_txt_count < count) do
      sleep 5
      elapsed_time = Time.now - start_time
      received_txt_count = txt_gateway.count
      # Elapsed time is how long we've been looping for results. It's not an accurate performance measure
      p "#{received_txt_count}/#{count} txts received at #{elapsed_time.to_i} seconds."
    end
  end

  def assert_messages
    p "assert_messages"
    assert_equal(
        count,
        InboundTxt.count(:received_at, :conditions => ["DATE(received_at) = ?", Time.zone.now.to_date]),
        "Inbound opt-out TXTs received")

    assert_equal(
        count,
        Txt.count(:sent_at, :conditions => ["DATE(sent_at) = ?", Time.zone.now.to_date]),
        "Outbound opt-out confirmation TXTs received")

    visitors.each do |visitor|
      visitor.assert_opted_out
    end
  end
end

OptOutTest.new(ARGV).run

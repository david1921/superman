#!/usr/bin/env script/runner

# Run script from RAILS_ROOT: ./test/system/leads_test.rb -e nightly 100
#
# -e     : Rails environment. Defaults to development
# number : number of coupon requests to create. Defaults to 10
#
# development environment doesn't cache, so it's slow unless you modify config/environments/development.rb

require "test/system/system_test"

class LeadsTest < SystemTest
  def run
    at_exit { stop_daemons }

    setup_data
    create_visitors
    start_gateway
    voice_gateway.delete_all_messages
    txt_gateway.delete_all_messages
    start_daemons
    visitors.each(&:send_lead)
    wait_for_outbound_messages
    send_cdrs
    assert_messages
    assert_cdrs
    print_performance_numbers
    puts "Done."
  end

end

LeadsTest.new(ARGV).run

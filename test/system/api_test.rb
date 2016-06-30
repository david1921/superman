#!/usr/bin/env script/runner

# Run script from RAILS_ROOT: ./test/system/api_test.rb -e nightly 100
#
#   -e     : Rails environment. Defaults to development
#   number : number of coupon requests to create. Defaults to 10
#
# Development environment doesn't cache, so it's slow unless you modify config/environments/development.rb

require "test/system/system_test"

class ApiTest < SystemTest
  attr_accessor :api_requestors
  
  def run
    at_exit { stop_daemons }

    setup_database
    start_gateway
    [txt_gateway, voice_gateway].each(&:delete_all_messages)
    start_daemons

    create_api_requestors
    api_requestors.each(&:invoke)
    wait_for_outbound_messages
    assert_messages
    print_performance_numbers
    puts "Done."
  end
  
  def setup_database
    p "setup_database"

    Publisher.destroy_all(:name => "Long Island Press")
    @publisher = Publisher.create!(:name => "Long Island Press", :label => "longislandpress")
    
    User.destroy_all(:email => "gharalam@moreyinteractive.com")
    user = User.create!(
      :email => "gharalam@moreyinteractive.com",
      :password => "secret",
      :password_confirmation => "secret",
      :publisher_ids => [@publisher.id]
    )
    Txt.destroy_all
    VoiceMessage.destroy_all
  end
  
  def create_api_requestors
    @api_requestors = []
    count.times { @api_requestors << ApiRequestor.new_with_random_type(@publisher) }
  end
  
  def txt_me_requests
    @txt_me_requests ||= (api_requestors.find_all { |api_requestor| api_requestor.is_a?(TxtApiRequestor) }.size)
  end

  def call_me_requests
    @call_me_requests ||= (api_requestors.find_all{ |api_requestor| api_requestor.is_a?(CallApiRequestor) }.size)
  end
end

ApiTest.new(ARGV).run

raise "Can't run system test in #{Rails.env} environment" unless ["test", "development", "nightly"].include?(Rails.env)


# Really shouldn't need this, but assertions don't fully-load without it
require "test/unit/assertions"
require 'faker'

class SystemTest
  include Test::Unit::Assertions

  attr_accessor :advertiser
  attr_accessor :count
  attr_accessor :placement
  attr_accessor :network_latency
  attr_accessor :visitors

  def initialize(args)
    args.delete("-e")
    args.delete(Rails.env)
    if args.first.blank?
      @count = 10
    else
      @count = args.first.to_i
    end
    raise ArgumentError, "test message count must be greater than 0" unless @count > 0

    @visitors = []
  end

  def setup_data
    p "setup_data"
    
    Offer.destroy_all :created_at => Time.now.beginning_of_day
    Advertiser.destroy_all :created_at => Time.now.beginning_of_day
    Publisher.destroy_all :created_at => Time.now.beginning_of_day
    Placement.destroy_all :created_at => Time.now.beginning_of_day
    Category.destroy_all :created_at => Time.now.beginning_of_day
    Store.destroy_all :created_at => Time.now.beginning_of_day
    
    Publisher.destroy_all(:name => "Westgate")
    publisher = Publisher.create!(:name => "Westgate", :password => "top_secret_password")

    Advertiser.destroy_all(:name => "System Test")
    @advertiser = publisher.advertisers.create!(:name => "System Test", :message => "click me", :voice_response_code => 1919)

    @placement = @advertiser.placements.create!(
      :publisher => publisher,
      :label => "p-test-westgate-01"
    )
  end

  def create_visitors
    count.times { visitors << Visitor.new(:placement => placement) }
    visitors.each(&:build_lead)
  end

  def start_gateway
    begin `#{AppConfig.receiver_start_command}` rescue puts($!) end
  end

  def start_daemons
    p "start_daemons"
    begin `#{AppConfig.sender_start_command}` rescue puts($!) end
  end

  def stop_daemons
    p "stop_daemons"
    # Mongrel is noisy about trying to stop if there's no running process
    begin `#{AppConfig.receiver_stop_command}` rescue Rails.logger.debug($!) end
    begin `#{AppConfig.sender_stop_command}` rescue puts($!) end
  end

  def print_performance_numbers
    { InboundTxt => "received",
      VoiceMessage => "sent",
      Txt => "sent",
      CallDetailRecord => "created"
    }.each do |k, v|
      print_performance_numbers_for_(k, v)
    end
  end

  # ms
  def measure_network_latency
    ping_output = `ping -c 4 -q localhost`
    @network_latency = ping_output[/= \d+\.\d+\/(\d+\.\d+)\/\d+\.\d+\/\d+\.\d+\ ms/, 1].to_f
  end
  
  def call_me_requests
    @call_me_requests ||= (visitors.find_all(&:call_me?).size)
  end
  
  def txt_me_requests
    @txt_me_requests ||= (visitors.find_all(&:txt_me?).size)
  end

  def txt_gateway
    @txt_gateway ||= Messaging::TxtGateway.new
  end

  def voice_gateway
    @voice_gateway ||= Messaging::VoiceGateway.new
  end

  def wait_for_outbound_messages
    p "wait_for_outbound_messages"
    start_time = Time.now
    elapsed_time = 0
    received_txt_count = 0
    received_voice_count = 0
    # Every request triggers a TXT message, and about half also trigger a voice message
    while (elapsed_time < 180 && (received_txt_count < txt_me_requests || received_voice_count < call_me_requests)) do
      sleep 5
      elapsed_time = Time.now - start_time
      received_txt_count = txt_gateway.count
      received_voice_count = voice_gateway.count
      # Elapsed time is how long we've been looping for results. It's not an accurate performance measure
      p "#{received_txt_count}/#{txt_me_requests} txts, #{received_voice_count}/#{call_me_requests} voice msgs received at #{elapsed_time.to_i} seconds."
    end
  end

  def send_cdrs
    voice_gateway.all_messages.each do |voice_gateway_message|
      voice_message_id = voice_gateway_message.p_t.to_i
      visitor = visitors.detect { |visitor| visitor.mobile_number == voice_gateway_message.mobile_number.phone_digits }
      visitor.send_cdr_data(voice_message_id)
    end
  end

  def assert_cdrs
    p "assert_cdrs"
    cdr_count = CallDetailRecord.count(:conditions => ["DATE(created_at) = UTC_DATE"])
    assert_equal(call_me_requests, cdr_count, "CDR count")
  end

  def assert_messages
    p "assert_messages"
    assert_equal(
        call_me_requests,
        VoiceMessage.count(:created_at, :conditions => ["DATE(created_at) = UTC_DATE and status = ?", "sent"]),
        "Coupon requests voice messages sent")
    assert_equal(
        txt_me_requests,
        Txt.count(:created_at, :conditions => ["DATE(created_at) = UTC_DATE and status = ?", "sent"]),
        "Coupon requests TXT messages sent")

    uncalled_visitors = visitors.reject(&:call_me?)
    conversion_count = Conversion.count(:conditions => ["DATE(created_at) = UTC_DATE"])
    assert_equal uncalled_visitors.size, conversion_count, "Conversion count"
  end
  
  def destroy(records)
    begin
      if records && records.any?
        records.each(&:destroy)
      end
    rescue Exception => e
      p e
    end
  end

  private

  def print_performance_numbers_for_(klass, verb)
    created_today =  ["DATE(created_at) = UTC_DATE"]
    if ((first_received_at = klass.minimum("#{verb}_at", :conditions => created_today)) &&
        (final_received_at = klass.maximum("#{verb}_at", :conditions => created_today)))
      elapsed_secs = [1, (final_received_at - first_received_at).to_i].max
      num_received = klass.count(:conditions => created_today)
      p "#{verb.capitalize} #{num_received} #{klass}s in #{elapsed_secs} seconds: #{num_received / elapsed_secs} messages per second."
    else
      p "#{verb.capitalize} no #{klass}s"
    end
  end
end

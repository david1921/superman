require "test/helpers/visitor_test_helper"

class Visitor < ActiveRecord::Base
  include VisitorTestHelper
  include Test::Unit::Assertions

  attr_accessor :new_lead_page_response_time, :placement, :create_lead_response_time, :txt_me
  attr_reader :lead, :mobile_number, :offer_xml, :state_code

  def self.new_label
    rand(1_000_000_000_000).to_s
  end

  def build_lead
    @lead = placement.leads.new(
      :name => random_name,
      :email => random_email,
      :mobile_number => mobile_number,
      :call_me => call_me?,
      :txt_me => txt_me?,
      :state_code => state_code,
      :use_credit_card => use_credit_card?,
      :remote_ip => random_ip,
      :query_parameters => { 'id' => affiliate_id }
    )
  end

  # ||= will reset @call_me if it's nil!
  def call_me?
    if @call_me.nil?
      @call_me = (rand < 0.3)
    end
    @call_me
  end

  # ||= will reset @txt_me if it's nil!
  def txt_me?
    if @txt_me.nil?
      @txt_me = (rand < 0.7)
    end
    @txt_me
  end
  
  def set_txt_or_call_me
    if call_me?
      lead.txt_me = (rand < 0.25)
    else
      lead.txt_me = true
    end
    @txt_me = lead.txt_me
  end

  def mobile_number
    @mobile_number ||= random_phone_number
  end

  def state_code
    @state_code ||= random_state_code
  end
  
  def affiliate_id
    @affiliate_id ||= rand < 0.5 ? "CD0001" : "CD6157"
  end

  def use_credit_card?
    if @use_credit_card.nil?
      @use_credit_card = (rand < 0.5)
    end
    @use_credit_card
  end

  def call_duration
    @call_duration ||= 5.0 + (rand(80) - 40)/10.0
  end

  def cdr_sid
    @cdr_sid ||= random_cdr_sid
  end

  def conversion_value
    @conversion_value ||= random_conversion_value
  end

  def send_opt_out_txt
    @mobile_number = random_phone_number
    today = Time.zone.now.to_date
    inbound_txt = InboundTxt.new(
      :accepted_time => Time.local(today.year, today.month, today.day, 0, 0, 0) + rand * 86_400,
      :keyword => "STOP",
      :message => "STOP",
      :originator_address => @mobile_number,
      :network_type => "gsm",
      :server_address => "898411",
      :carrier => random_carrier
    )

    Net::HTTP.post_form(receiver_uri, {
      "ResponseType" => "NORMAL",
      "Message" => inbound_txt.message,
      "OriginatorAddress" => inbound_txt.originator_address,
      "ServerAddress" => inbound_txt.server_address,
      "AcceptedTime" => inbound_txt.accepted_time.localtime.strftime("%d%b,%y %H:%M:%S"),
      "DeliveryType" => "SMS",
      "Carrier" => inbound_txt.carrier,
      "NetworkType" => inbound_txt.network_type
    })
  end

  def send_westgate_lead
    Net::HTTP.post_form(create_westgate_lead_uri, {
      "first_name" => lead.first_name,
      "last_name" => lead.last_name,
      "email" => lead.email,
      "mobile_phone" => lead.mobile_number,
      "connect_me" => lead.call_me? ? "1" : "0",
      "state_code" => lead.state_code,
      "use_credit_card" => lead.use_credit_card,
      "client_ip" => lead.remote_ip,
      "password" => placement.publisher.password
    })
  end

  def view_coupons_page
    Net::HTTP.get(coupons_uri)
  end

  def send_lead
    Net::HTTP.post_form(create_lead_uri, {
      "placement_id" => placement.to_param,
      "lead[name]" => lead.name,
      "lead[email]" => lead.email,
      "lead[mobile_number]" => lead.mobile_number,
      "lead[call_me]" => lead.call_me?,
      "lead[txt_me]" => lead.txt_me?,
      "lead[query_parameters][id]" => lead.query_parameters['id']
    })
  end

  def send_cdr_data(voice_message_id)
    if call_me?
      Net::HTTP.post_form(update_one_call_detail_record_sid_uri, {
        "id" => voice_message_id,
        "call_detail_record_sid" => cdr_sid
      })
      Net::HTTP.post_form(create_call_detail_record_uri, {
        :sid => cdr_sid,
        :date_time => '2008-09-16 12:14:56',
        :viewer_phone_number => mobile_number[1..-1],
        :center_phone_number => 'Transfer | 6266745901',
        :intelligent_minutes => 0.6,
        :talk_minutes => call_duration,
        :enhanced_minutes => 0.0
      })
    end
  end
  
  def assert_opted_out
    assert_not_nil(MobilePhone.find_by_number(@mobile_number))
  end
    
  def assert_lead_created
    assert(Lead.exists?(:first_name => lead.first_name, :last_name => lead.last_name, :mobile_number => lead.mobile_number), 
      "Expected #{lead} in database")
  end
  
  def advertiser
    placement.advertiser
  end

  def create_lead_uri
    @create_lead_uri ||= URI.parse("http://#{AppConfig.receiver_address}:#{AppConfig.receiver_port}/placements/#{placement.id}/leads")
  end
  
  def coupons_uri
    @coupons_uri ||= URI.parse("http://#{AppConfig.receiver_address}:#{AppConfig.receiver_port}/publishers/#{placement.publisher.id}/offers")
  end
  
  def method_missing(id)
    uri_for_($1) if id.id2name =~ /(.+)_uri$/
  end

  private

  def uri_for_(action)
    AppConfig.instance_eval {
      URI.parse("http://#{receiver_address}:#{receiver_port}" + send("#{action}_path"))
    }
  end
end

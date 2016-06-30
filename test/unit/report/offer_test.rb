require File.dirname(__FILE__) + "/../../test_helper"

class OfferTest < ActiveSupport::TestCase
  def test_click_count
    offer = offers(:my_space_burger_king_free_fries)
    assert_equal 0, offer.click_counts.size, "Offer should initially have no clicks"
    
    offer.click_counts.create! :publisher => offer.publisher, :count => 1, :created_at => Time.zone.parse("2008-12-14 12:34:56")
    offer.click_counts.create! :publisher => offer.publisher, :count => 2, :created_at => Time.zone.parse("2008-12-15 00:00:00")
    offer.click_counts.create! :publisher => offer.publisher, :count => 3, :created_at => Time.zone.parse("2008-12-15 23:59:59")
    offer.click_counts.create! :publisher => offer.publisher, :count => 4, :created_at => Time.zone.parse("2008-12-15 12:34:56")
    offer.click_counts.create! :publisher => offer.publisher, :count => 5, :created_at => Time.zone.parse("2008-12-16 23:59:59")
    
    check_counts offer, :click, "2008-11-30", "2008-12-30", 15
    check_counts offer, :click, "2008-11-30", "2008-12-13", 0
    check_counts offer, :click, "2008-12-14", "2008-12-16", 15
    check_counts offer, :click, "2008-12-15", "2008-12-16", 14
    check_counts offer, :click, "2008-12-16", "2008-12-16", 8
    check_counts offer, :click, "2008-12-17", "2008-12-30", 5
  end
  
  def test_click_counts_with_clicks_on_search_period_boundaries
    ClickCount.delete_all
    offer = Factory :offer
    
    # not counted
    Timecop.freeze(Time.parse("2011-09-30T23:59:59Z"))
    offer.record_click offer.publisher.id
    
    # counted
    Timecop.freeze(Time.zone.parse("2011-09-30 23:59:59"))
    offer.record_click offer.publisher.id
    
    # counted
    Timecop.freeze(Time.zone.parse("2011-10-01 00:00:00"))
    offer.record_click offer.publisher.id
    offer.record_click offer.publisher.id
    
    # counted
    Timecop.freeze(Time.zone.parse("2011-10-15 12:34:00"))
    offer.record_click offer.publisher.id
    
    # counted
    Timecop.freeze(Time.parse("2011-10-31T23:59:59Z"))
    offer.record_click offer.publisher.id
    
    # counted
    Timecop.freeze(Time.zone.parse("2011-10-31 23:59:59"))
    offer.record_click offer.publisher.id
    offer.record_click offer.publisher.id
    offer.record_click offer.publisher.id
    
    # counted
    Timecop.freeze(Time.zone.parse("2011-11-01 00:00:00"))
    offer.record_click offer.publisher.id
    
    # not counted
    Timecop.freeze(Time.zone.parse("2011-11-02 00:00:00"))
    offer.record_click offer.publisher.id      
    
    Timecop.return
    
    dates = Date.new(2011, 10, 1) .. Date.new(2011, 10, 31)
    
    assert_equal 9, offer.clicks_count(dates)
  end
  
  def test_txt_count
    offer = offers(:my_space_burger_king_free_fries)
    Lead.destroy_all
    Txt.destroy_all
    assert_equal 0, offer.leads.size, "Offer should initially have no leads"
    
    create_txt = lambda do |n, i, t, s|
      lead = offer.leads.create! :publisher => offer.publisher, :mobile_number => n + i.to_s, :txt_me => true, :created_at => t
      Txt.find_by_source_type_and_source_id('Lead', lead.id).update_attributes!(:status => s, :created_at => t)
    end
    
    1.times { |i| create_txt.call("123456789", i, Time.zone.parse("2008-12-14 12:34:56"), "sent") }
    2.times { |i| create_txt.call("123456788", i, Time.zone.parse("2008-12-15 00:00:00"), "sent") }
    3.times { |i| create_txt.call("123456787", i, Time.zone.parse("2008-12-15 23:59:59"), "sent") }
    4.times { |i| create_txt.call("123456786", i, Time.zone.parse("2008-12-15 12:34:56"), "sent") }
    5.times { |i| create_txt.call("123456786", i, Time.zone.parse("2008-12-16 23:59:59"), "sent") }
    #
    # Should not count txts unless status is "sent"
    #
    6.times { |i| create_txt.call("223456789", i, Time.zone.parse("2008-12-14 12:34:56"), "created") }
    7.times { |i| create_txt.call("223456786", i, Time.zone.parse("2008-12-15 12:34:56"), "created") }

    check_counts offer, :txt, "2008-11-30", "2008-12-30", 15
    check_counts offer, :txt, "2008-11-30", "2008-12-13", 0
    check_counts offer, :txt, "2008-12-14", "2008-12-16", 15
    check_counts offer, :txt, "2008-12-15", "2008-12-16", 14
    check_counts offer, :txt, "2008-12-16", "2008-12-16", 5
    check_counts offer, :txt, "2008-12-17", "2008-12-30", 0
  end
  
  def test_voice_call_count
    offer = offers(:my_space_burger_king_free_fries)
    Lead.destroy_all
    VoiceMessage.destroy_all
    assert_equal 0, offer.leads.size, "Offer should initially have no leads"
    
    create_voice_message = lambda do |n, i, t, s|
      lead = offer.leads.create! :publisher => offer.publisher, :mobile_number => n + i.to_s, :name => "Abe Zee", :call_me => true, :created_at => t
      VoiceMessage.find_by_lead_id(lead).update_attributes!(:status => s, :created_at => t)
    end
    
    1.times { |i| create_voice_message.call("123456789", i, Time.zone.parse("2008-12-14 12:34:56"), "sent") }
    2.times { |i| create_voice_message.call("123456788", i, Time.zone.parse("2008-12-15 00:00:00"), "sent") }
    3.times { |i| create_voice_message.call("123456787", i, Time.zone.parse("2008-12-15 23:59:59"), "sent") }
    4.times { |i| create_voice_message.call("123456786", i, Time.zone.parse("2008-12-15 12:34:56"), "sent") }
    5.times { |i| create_voice_message.call("123456786", i, Time.zone.parse("2008-12-16 23:59:59"), "sent") }
    #
    # Should not count voice messages unless status is "sent"
    #
    6.times { |i| create_voice_message.call("223456789", i, Time.zone.parse("2008-12-14 12:34:56"), "created") }
    7.times { |i| create_voice_message.call("223456786", i, Time.zone.parse("2008-12-15 12:34:56"), "created") }

    check_counts offer, :voice_message, "2008-11-30", "2008-12-30", 15
    check_counts offer, :voice_message, "2008-11-30", "2008-12-13", 0
    check_counts offer, :voice_message, "2008-12-14", "2008-12-16", 15
    check_counts offer, :voice_message, "2008-12-15", "2008-12-16", 14
    check_counts offer, :voice_message, "2008-12-16", "2008-12-16", 5
    check_counts offer, :voice_message, "2008-12-17", "2008-12-30", 0
  end

  def test_print_count
    offer = offers(:my_space_burger_king_free_fries)
    Lead.destroy_all
    assert_equal 0, offer.leads.size, "Offer should initially have no leads"
    
    create_print_lead = lambda do |i, t|
      offer.leads.create! :publisher => offer.publisher, :print_me => true, :created_at => t
    end
    
    1.times { |i| create_print_lead.call(i, Time.zone.parse("2008-12-14 12:34:56")) }
    2.times { |i| create_print_lead.call(i, Time.zone.parse("2008-12-15 00:00:00")) }
    3.times { |i| create_print_lead.call(i, Time.zone.parse("2008-12-15 23:59:59")) }
    4.times { |i| create_print_lead.call(i, Time.zone.parse("2008-12-15 12:34:56")) }
    5.times { |i| create_print_lead.call(i, Time.zone.parse("2008-12-16 23:59:59")) }

    check_counts offer, :print, "2008-11-30", "2008-12-30", 15
    check_counts offer, :print, "2008-11-30", "2008-12-13", 0
    check_counts offer, :print, "2008-12-14", "2008-12-16", 15
    check_counts offer, :print, "2008-12-15", "2008-12-16", 14
    check_counts offer, :print, "2008-12-16", "2008-12-16", 5
    check_counts offer, :print, "2008-12-17", "2008-12-30", 0
  end
  
  def test_email_count
    Lead.destroy_all
    offer = offers(:my_space_burger_king_free_fries)
    assert_equal 0, offer.leads.size, "Offer should initially have no leads"
    
    create_email_lead = lambda do |i, t|
      offer.leads.create! :publisher => offer.publisher, :email_me => true, :email => "user#{i}@example.com", :created_at => t
    end
    
    1.times { |i| create_email_lead.call(i, Time.zone.parse("2008-12-14 12:34:56")) }
    2.times { |i| create_email_lead.call(i, Time.zone.parse("2008-12-15 00:00:00")) }
    3.times { |i| create_email_lead.call(i, Time.zone.parse("2008-12-15 23:59:59")) }
    4.times { |i| create_email_lead.call(i, Time.zone.parse("2008-12-15 12:34:56")) }
    5.times { |i| create_email_lead.call(i, Time.zone.parse("2008-12-16 23:59:59")) }

    check_counts offer, :email, "2008-11-30", "2008-12-30", 15
    check_counts offer, :email, "2008-11-30", "2008-12-13", 0
    check_counts offer, :email, "2008-12-14", "2008-12-16", 15
    check_counts offer, :email, "2008-12-15", "2008-12-16", 14
    check_counts offer, :email, "2008-12-16", "2008-12-16", 5
    check_counts offer, :email, "2008-12-17", "2008-12-30", 0
  end
  
  private
  
  def check_counts(offer, member, date_lo, date_hi, count)
    dates = date_range_from_strings(date_lo, date_hi)
    assert_equal count, offer.send("#{member}s_count", dates)
  end
  
  def date_range_from_strings(date_lo, date_hi)
    parse_date = lambda { |text| Date.new(*ParseDate.parsedate(text)[0, 3]) }
    parse_date.call(date_lo) .. parse_date.call(date_hi)
  end
end

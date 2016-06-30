require File.dirname(__FILE__) + "/../test_helper"

class LeadTest < ActiveSupport::TestCase
  def test_create
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true
    )
    assert_equal("16051629100", lead.mobile_number, "mobile number")

    txt = associated_txt("16051629100", lead)
    assert_equal "TXT411: Code COKESWAY: $1 off a 6-pack purchase @ Safeway. 1 per customer. Std msg chrgs apply. T&Cs at txt411.com", txt.message

    voice_message = VoiceMessage.find_by_mobile_number("16051629100")
    assert_nil(voice_message, "Should not create new outbound VoiceMessage until Txt is sent")
  end

  def test_create_with_blank_name_should_not_raise_exception
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true
    )

    lead = offer.leads.create(:publisher => offer.publisher, :email => "me@gmail.com", :mobile_number => "(605) 162-9100", :txt_me => true)

    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => nil,
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true
    )
  end

  def test_blank_mobile_number
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :txt_me => true
    )
    assert_equal(1, lead.errors.size, "Shouldn't have duplicate validation errors for mobile number. Errors: #{lead.errors.full_messages}")
  end

  def test_blank_email
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create(:publisher => offer.publisher, :email => "", :email_me => true)
    assert_equal(1, lead.errors.size, "Blank email should be invalid. Errors: #{lead.errors.full_messages}")
  end

  def test_invalid_email
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create(:publisher => offer.publisher, :email => "foobar", :email_me => true)
    assert_equal(1, lead.errors.size, "Invalid email should be invalid. Errors: #{lead.errors.full_messages}")
  end

  def test_spam_limit_only_for_txt
    offer = Factory(:offer)
    advertiser = offer.advertiser

    Timecop.freeze(23.hours.ago) do
      10.times do
        lead = offer.leads.create!(
          :publisher => offer.publisher,
          :name => "My Name",
          :email => "me@gmail.com",
          :mobile_number => "(605) 162-9100",
          :txt_me => true,
          :remote_ip => "192.168.1.1"
        )
      end
    end

    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :remote_ip => "192.168.1.1"
    )
    assert(lead.errors.present?, "Should not be able to enter more than 10 times in one week. Offer thinks it has #{offer.leads.size} in memory. #{offer.leads(true).count} in the database. Lead count_like_me return #{lead.send :count_like_me}")
  end
  
  def test_default_limits_for_email
    offer = Factory(:offer)
    advertiser = offer.advertiser
    assert_equal nil, advertiser.coupon_limit, "coupon_limit"

    Timecop.freeze(1.hour.ago) do
      10.times do
        lead = offer.leads.create!(
          :publisher => offer.publisher,
          :name => "My Name",
          :email => "me@gmail.com",
          :remote_ip => "192.168.1.1",
          :email_me => true
        )
        assert lead.errors.empty?, "Should be able to enter first time if there's a coupon limit, but had errors: #{lead.errors.full_messages}"
      end    
    end
    
    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :remote_ip => "192.168.1.1",
      :email_me => true
    )
    assert(lead.errors.present?, "Should not be able to enter more than 10 times in one week. Offer thinks it has #{offer.leads.size} in memory. #{offer.leads(true).count} in the database. Lead count_like_me return #{lead.send :count_like_me}")
  end

  def test_offer_limits_for_txt
    advertiser = advertisers(:burger_king)
    advertiser.coupon_limit = 1
    advertiser.save!
    
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :remote_ip => "192.168.1.1"
    )
    assert(lead.errors.empty?, "Should be able to enter first time if there's a coupon limit, but had errors: #{lead.errors.full_messages}")

    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :remote_ip => "192.168.1.1"
    )
    assert(lead.errors.any?, "Should have errors if try to enter more one time if there's a coupon limit")
  end
  
  def test_offer_limits_for_email
    advertiser = advertisers(:burger_king)
    advertiser.coupon_limit = 1
    advertiser.save!
    
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :remote_ip => "192.168.1.1",
      :email_me => true
    )
    assert(lead.errors.empty?, "Should be able to email one time if there's a coupon limit")

    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :remote_ip => "192.168.1.1",
      :email_me => true
    )
    assert(lead.errors.any?, "Should be able to email only one time if there's a coupon limit")
  end
  
  def test_create_and_call_me
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :call_me => true
    )

    txt = associated_txt("16051629100", lead)
    assert_equal "TXT411: Code COKESWAY: $1 off a 6-pack purchase @ Safeway. 1 per customer. Std msg chrgs apply. T&Cs at txt411.com", txt.message

    voice_message = VoiceMessage.find_by_mobile_number("16051629100")
    assert_nil(voice_message, "Should not create new outbound VoiceMessage until Txt is sent")
  end

  def test_truncate_long_txt_messages
    advertiser = publishers(:my_space).advertisers.create!(:name => "China View Restaurant", :tagline => "Best Chinese food in downtown!")
    offer = advertiser.offers.create!(
      :message => "Order three entrees and get a fourth entree and extra-large side of sticky rice for free at our newly-remodeled downtown lounge.",
      :terms => "Limit one per customer. Not valid with any other offer. Expires 06/20/09."
    )
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :call_me => true
    )

    txt = associated_txt("16051629100", lead)
    assert_equal(
      "TXT411: Order three entrees and get a fourth entree and extra-large side of sticky rice for free at our newly-remodel... Std msg chrgs apply. T&Cs at txt411.com", 
      txt.message)
  end

  def test_after_sent
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true
    )

    txt = associated_txt("16051629100", lead)
    assert_equal "TXT411: Code COKESWAY: $1 off a 6-pack purchase @ Safeway. 1 per customer. Std msg chrgs apply. T&Cs at txt411.com", txt.message
  
    txt.sent_at = Time.now - 90
    txt.status = "sent"
    lead.after_sent(txt)

    voice_message = VoiceMessage.find_by_mobile_number("16051629100")
    assert_nil(voice_message, "Should not create new outbound VoiceMessage if call_me is false")
  end

  def test_after_sent_and_call_me
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :call_me => true
    )

    txt = Txt.find_by_mobile_number("16051629100")
    txt.sent_at = Time.now
    txt.status = "sent"
    lead.after_sent(txt)

    voice_message = VoiceMessage.find_by_mobile_number("16051629100")
    assert_not_nil(voice_message, "Should create new outbound VoiceMessage after TXT is sent")
    assert_equal(offer.advertiser.voice_response_code, voice_message.voice_response_code, "Voice message voice_response_code")
    assert_equal("created", voice_message.status, "voice_message status")
    assert_equal_date_times(txt.sent_at + AppConfig.voice_message_delay_seconds, voice_message.send_at, "voice_message send_at")
  end

  def test_invalid_if_opted_out
    MobilePhone.from_params(:number => "1 919 787 0009", :opt_out => true)
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "1 919 787 0009",
      :call_me => true
    )
    assert(!lead.valid?, "Lead for opted-out number should be invalid")
    assert(!Lead.exists?(:mobile_number => "19197870009"))
  end

  def test_normalize_mobile_number
    lead = Lead.new(:mobile_number => "(605) 162-9100")
    lead.normalize_mobile_number
    assert_equal("16051629100", lead.mobile_number, "mobile number")

    lead = Lead.new(:mobile_number => "1 (605) 162-9100")
    lead.normalize_mobile_number
    assert_equal("16051629100", lead.mobile_number, "mobile number")

    lead = Lead.new(:mobile_number => "6051629100")
    lead.normalize_mobile_number
    assert_equal("16051629100", lead.mobile_number, "mobile number")

    lead = Lead.new(:mobile_number => "16051629100")
    lead.normalize_mobile_number
    assert_equal("16051629100", lead.mobile_number, "mobile number")
  end

  def test_names
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :first_name => "Alexander",
      :last_name => "Bell",
      :email => "me@gmail.com",
      :mobile_number => "1 919 787 0009",
      :txt_me => true
    )
    assert(lead.valid?, "first_name + last_name should be valid, but had errors: #{lead.errors.full_messages}")
    assert_equal("Alexander Bell", lead.name, "name")
    assert_equal("Alexander", lead.first_name, "first_name")
    assert_equal("Bell", lead.last_name, "last_name")

    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "Alexander Bell",
      :email => "me@gmail.com",
      :mobile_number => "1 919 787 0010",
      :txt_me => true
    )
    assert(lead.valid?, "name should be valid, but had errors: #{lead.errors.full_messages}")
    assert_equal("Alexander Bell", lead.name, "name")
    assert_equal("Alexander", lead.first_name, "first_name")
    assert_equal("Bell", lead.last_name, "last_name")

    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "Alexander Graham Bell",
      :email => "me@gmail.com",
      :mobile_number => "1 919 787 0011",
      :txt_me => true
    )
    assert(lead.valid?, "name should be valid, but had errors: #{lead.errors.full_messages}")
    assert_equal("Alexander Graham Bell", lead.name, "name")
    assert_equal("Alexander Graham", lead.first_name, "first_name")
    assert_equal("Bell", lead.last_name, "last_name")

    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => " John   Jacob   Jingleheimer  Schmidt ",
      :email => "me@gmail.com",
      :mobile_number => "1 919 787 0012",
      :txt_me => true
    )
    assert(lead.valid?, "name should be valid, but had errors: #{lead.errors.full_messages}")
    assert_equal("John Jacob Jingleheimer Schmidt", lead.name, "name")
    assert_equal("John Jacob Jingleheimer", lead.first_name, "first_name")
    assert_equal("Schmidt", lead.last_name, "last_name")

    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "John",
      :email => "me@gmail.com",
      :mobile_number => "1 919 787 0013",
      :txt_me => true
    )
    assert(lead.valid?, "name should be valid, but had errors: #{lead.errors.full_messages}")
    assert_equal("John", lead.name, "name")
    assert_equal("John", lead.first_name, "first_name")
    assert_equal("", lead.last_name, "last_name")
  end

  def test_find_by_name
    offer = offers(:my_space_burger_king_free_fries)
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "Dan Flanegan",
      :email => "me@gmail.com",
      :mobile_number => "1 919 787 0011",
      :txt_me => true
    )
    lead = Lead.find_by_name("Dan Flanegan")
    assert_not_nil(lead)
  end

  def test_print_email_txt_or_call_required
    offer = offers(:my_space_burger_king_free_fries)
    
    lead = offer.leads.create(:publisher => offer.publisher, :print_me => true)
    assert(lead.valid?, "print_me? should be valid, but had errors: #{lead.errors.full_messages}")

    lead = offer.leads.create(:publisher => offer.publisher, :email_me => true, :email => "me@gmail.com")
    assert(lead.valid?, "email_me? should be valid, but had errors: #{lead.errors.full_messages}")
    
    lead = offer.leads.create(
      :publisher => offer.publisher,
      :name => "Alexander Bell",
      :mobile_number => "1 919 787 0009",
      :txt_me => true,
      :call_me => true
    )
    assert(lead.valid?, "txt_me? and call_me? should be valid, but had errors: #{lead.errors.full_messages}")

    lead = offer.leads.create(:publisher => offer.publisher, :name => "Alexander Bell", :mobile_number => "1 919 787 0010", :txt_me => true)
    assert(lead.valid?, "txt_me? should be valid, but had errors: #{lead.errors.full_messages}")

    lead = offer.leads.create(:publisher => offer.publisher, :name => "Alexander Bell", :mobile_number => "1 919 787 0011", :call_me => true)
    assert(lead.valid?, "call_me? should be valid, but had errors: #{lead.errors.full_messages}")

    lead = offer.leads.create(:publisher => offer.publisher, :name => "Alexander Bell", :mobile_number => "1 919 787 0012")
    assert(!lead.valid?, "No print_me?, email_me?, txt_me? or call_me? should be invalid")
    
  end
  
  def test_message
    offer = advertisers(:burger_king).offers.create!( :message => "Offer 2", :txt_message => "Custom message")
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true
    )
    txt = associated_txt("16051629100", lead)
    assert_equal "TXT411: Custom message. Std msg chrgs apply. T&Cs at txt411.com", txt.message, "Message should be custom offer message"
  end
  
  def test_message_strip_periods
    offer = advertisers(:burger_king).offers.create!( :message => "Offer 2", :message => "Custom message.", :terms => "1-time only.")
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :offer => offer
    )
    txt = associated_txt("16051629100", lead)
    assert_equal "TXT411: Custom message. Std msg chrgs apply. T&Cs at txt411.com", txt.message, "Message should be custom offer message"
  end
  
  def test_message_default
    offer = advertisers(:burger_king).offers.create!( :message => "Offer 2")

    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "My Name",
      :email => "me@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true,
      :offer => offer
    )
    txt = associated_txt("16051629100", lead)
    assert_equal "TXT411: Offer 2. Std msg chrgs apply. T&Cs at txt411.com", txt.message, "Message should be default advertiser message"
  end
  
  def test_custom_txt_header
    offer = advertisers(:changos).offers.create!(:message => "Free Taco")
    lead = offer.leads.create!(:publisher => offer.publisher, :mobile_number => "(605) 162-9100", :txt_me => true)
    txt = associated_txt("16051629100", lead)
    assert_equal "MySDH.com: Free Taco. Std msg chrgs apply. T&Cs at txt411.com", txt.message, "TXT message with custom header"
  end

  def test_auto_expiration_footer
    offer = advertisers(:changos).offers.create!(:message => "Free Taco", :expires_on => "Dec 01, 2008")
    lead = offer.leads.create!(:publisher => offer.publisher, :mobile_number => "(605) 162-9100", :txt_me => true)
    txt = associated_txt("16051629100", lead)
    assert_equal "MySDH.com: Free Taco. Exp12/01/08. Std msg chrgs apply. T&Cs at txt411.com", txt.message, "TXT message with auto expiration footer"
  end

  def test_limit_clipping
    offer = Factory(:offer)

    Timecop.freeze(2.hours.ago) do
      10.times do
        lead = offer.leads.create!(:publisher => offer.publisher, :print_me => true, :remote_ip => "192.168.1.1")
        assert lead.valid?, "lead should be valid for 10 printings"
      end
    end

    lead = offer.leads.create(:publisher => offer.publisher, :print_me => true, :remote_ip => "192.168.1.1")
    assert !lead.valid?, "lead should not be valid for 11 printings.  Offer thinks it has #{offer.leads.size} in memory. #{offer.leads(true).count} in the database. Lead count_like_me return #{lead.send :count_like_me}"
  end

  def test_limit_clipping_if_advertiser_limit
    offer = offers(:my_space_burger_king_free_fries)
    advertiser = offer.advertiser
    advertiser.coupon_limit = 1
    advertiser.save!
    
    lead = offer.leads.create!(:publisher => offer.publisher, :print_me => true, :remote_ip => "192.168.1.1")
    assert lead.valid?, "lead should be valid for first print"
    
    lead = offer.leads.build(:publisher => offer.publisher, :print_me => true, :remote_ip => "192.168.1.1")
    assert !lead.valid?, "lead should not be valid for second print from same IP address"
    assert_match /may only be clipped/i, lead.errors.on_base
  end
  
  def test_txt_clipping_with_intro_txt
    offer = offers(:changos_buy_two_tacos)
    offer.advertiser.publisher.update_attributes! :send_intro_txt => true

    Txt.destroy_all
    lead = offer.leads.create!(
      :publisher => offer.publisher,
      :name => "John Doe",
      :email => "john@gmail.com",
      :mobile_number => "(605) 162-9100",
      :txt_me => true
    )
    assert_equal 1, Txt.count, "Should not create an intro message for web coupons"
    
    txt = Txt.first
    assert_equal "16051629100", txt.mobile_number
    assert_equal "MySDH.com: Changos: Buy two tacos & get one FREE. Expires 12/15/09. Std msg chrgs apply. T&Cs at txt411.com", txt.message
  end

  private
  
  def associated_txt(mobile_number, lead)
    txts = Txt.find_all_by_mobile_number(mobile_number)
    assert 1 == txts.size
    returning txts.detect { |txt| lead == txt.source } do |txt|
      assert_not_nil txt
      assert_equal "created", txt.status
    end
  end
end

require File.dirname(__FILE__) + "/../test_helper"

class TxtOfferTest < ActiveSupport::TestCase
  
  def test_create_without_short_code
    txt_offer = advertisers(:changos).txt_offers.create(:keyword => "sdhtaco", :message => "my message")
    assert txt_offer.valid?, "Should be valid with auto-assigned short code"
    assert !txt_offer.new_record?
    assert_equal "898411", txt_offer.short_code
    assert !txt_offer.deleted
  end
  
  def test_txts_count
    start_time = Time.now
    Time.expects(:now).at_least_once.returns(start_time)
    TxtOffer.clear_cache
    
    txt_offer = advertisers(:changos).txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another absolutely free"
    )
    create_inbound_txt = lambda do |count, accepted_time, created_time, status|
      count.times do |i|
        inbound_txt = InboundTxt.create_from_gateway!(
          "Message"           => "sdhtaco plz",
          "AcceptedTime"      => accepted_time,
          "NetworkType"       => "gsm",
          "ServerAddress"     => "898411",
          "OriginatorAddress" => "1626674%04d" % i,
          "Carrier"           => "t-mobile"
        )
        txt = Txt.find_by_source_type_and_source_id('InboundTxt', inbound_txt.id)
        txt.update_attributes! :created_at => Time.parse(created_time), :status => status
      end
    end
    create_inbound_txt.call( 1, "15Sep,08 15:59:59", "15 Sep 2008 23:59:59 UTC", "sent")
    create_inbound_txt.call( 2, "15Sep,08 16:00:00", "16 Sep 2008 00:00:00 UTC", "sent")
    create_inbound_txt.call( 3, "16Sep,08 04:34:56", "16 Sep 2008 12:34:56 UTC", "sent")
    create_inbound_txt.call( 5, "17Sep,08 04:34:57", "17 Sep 2008 12:34:57 UTC", "error")
    create_inbound_txt.call( 7, "17Sep,08 15:59:59", "17 Sep 2008 23:59:59 UTC", "sent")
    create_inbound_txt.call(11, "17Sep,08 15:59:59", "17 Sep 2008 23:59:59 UTC", "error")
    create_inbound_txt.call(13, "17Sep,08 16:00:00", "18 Sep 2008 00:00:00 UTC", "sent")

    assert_equal 26, txt_offer.txts_count(Date.new(2008, 9, 15) .. Date.new(2008, 9, 18)), "txts_count"
    assert_equal 12, txt_offer.txts_count(Date.new(2008, 9, 16) .. Date.new(2008, 9, 17)), "txts_count"
  end
  
  def test_keyword_unique_per_short_code
    advertiser = advertisers(:changos)
    txt_offer_1 = advertiser.txt_offers.create!(:short_code => " 898411  ", :keyword => " sDhtAcO ", :message => "Message 1")
    assert_equal "898411", txt_offer_1.short_code
    assert_equal "SDHTACO", txt_offer_1.keyword

    txt_offer_2 = advertiser.txt_offers.new(:short_code => "898411", :keyword => " sdhtaco ", :message => "Message 2")
    assert !txt_offer_2.valid?, "Offer should not be valid with duplicate short code and keyword"
    assert txt_offer_2.errors.on(:keyword), "Offer should have a keyword error"

    txt_offer_3 = advertiser.txt_offers.create!(:short_code => " 898411 ", :keyword => " sdhtako ", :message => "Message 3")
    assert_equal "898411", txt_offer_3.short_code
    assert_equal "SDHTAKO", txt_offer_3.keyword

    txt_offer_4 = advertiser.txt_offers.create!(:short_code => " 898412 ", :keyword => " sdhtaco ", :message => "Message 4")
    assert_equal "898412", txt_offer_4.short_code
    assert_equal "SDHTACO", txt_offer_4.keyword
  end
  
  def test_unique_keyword_validation_ignores_deleted_txt_offers
    advertiser = advertisers(:changos)
    txt_offer_1 = advertiser.txt_offers.create!(:short_code => " 898411  ", :keyword => " sDhtAcO ", :message => "Message 1", :deleted => true)
    assert_equal "898411", txt_offer_1.short_code
    assert_equal "SDHTACO", txt_offer_1.keyword

    txt_offer_2 = advertiser.txt_offers.create!(:short_code => "898411", :keyword => " sdhtaco ", :message => "Message 2")
    assert_equal "898411", txt_offer_2.short_code
    assert_equal "SDHTACO", txt_offer_2.keyword

    txt_offer_3 = advertiser.txt_offers.create!(:short_code => " 898411 ", :keyword => " sdhtako ", :message => "Message 3")
    assert_equal "898411", txt_offer_3.short_code
    assert_equal "SDHTAKO", txt_offer_3.keyword

    txt_offer_4 = advertiser.txt_offers.create!(:short_code => " 898412 ", :keyword => " sdhtaco ", :message => "Message 4")
    assert_equal "898412", txt_offer_4.short_code
    assert_equal "SDHTACO", txt_offer_4.keyword
  end
  
  def test_appears_on_only
    advertiser = advertisers(:changos)
    
    txt_offer = advertisers(:changos).txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another absolutely free",
      :appears_on => "2008 Nov 16"
    )
    test_inbound_txt = lambda do |accepted_time, response_expected|
      phone_number = "16266745901"
      advertiser.publisher.update_attributes! :send_intro_txt => false
      TxtOffer.clear_cache
      Txt.destroy_all
      inbound_txt = nil
      
      assert_difference 'Txt.count', (response_expected ? 1 : 0), accepted_time do 
        inbound_txt = InboundTxt.create_from_gateway!(
          "Message"           => "Sdhtaco plz",
          "AcceptedTime"      => accepted_time,
          "NetworkType"       => "gsm",
          "ServerAddress"     => "898411",
          "OriginatorAddress" => phone_number,
          "Carrier"           => "t-mobile"
        )
      end
      if response_expected
        assert_equal txt_offer, inbound_txt.txt_offer, accepted_time
        txt = Txt.first
        assert_equal inbound_txt, txt.source, accepted_time
        message = "MySDH.com: Buy one taco, get another absolutely free. Std msg chrgs apply. T&Cs at txt411.com"
        assert_equal message, txt.message, accepted_time
      end

      advertiser.publisher.update_attributes! :send_intro_txt => true
      TxtOffer.clear_cache
      Txt.destroy_all
      MobilePhone.find_by_number(phone_number).try(:destroy)
      inbound_txt = nil
      
      assert_difference 'Txt.count', (response_expected ? 2 : 0), accepted_time do 
        inbound_txt = InboundTxt.create_from_gateway!(
          "Message"           => "Sdhtaco plz",
          "AcceptedTime"      => accepted_time,
          "NetworkType"       => "gsm",
          "ServerAddress"     => "898411",
          "OriginatorAddress" => phone_number,
          "Carrier"           => "t-mobile"
        )
      end
      if response_expected
        assert_equal txt_offer, inbound_txt.txt_offer, accepted_time
        txt = Txt.all.detect { |txt| txt.message =~ /coupons to your mobile/i }
        assert_not_nil txt, accepted_time
        assert_equal inbound_txt, txt.source, accepted_time
        txt.destroy
        
        txt = Txt.first
        assert_equal inbound_txt, txt.source, accepted_time
        message = "MySDH.com: Buy one taco, get another absolutely free. Std msg chrgs apply"
        assert_equal message, txt.message, accepted_time
      end
    end
    
    test_inbound_txt.call "01Aug,07 12:23:56", false
    test_inbound_txt.call "15Nov,08 15:59:59", false
    test_inbound_txt.call "15Nov,08 16:00:00", true
    test_inbound_txt.call "16Nov,08 12:34:56", true
    test_inbound_txt.call "17Nov,08 15:59:59", true
    test_inbound_txt.call "17Nov,08 16:00:00", true
    test_inbound_txt.call "01Aug,09 12:34:56", true
  end
  
  def test_expires_on_only
    advertiser = advertisers(:changos)
    
    txt_offer = advertisers(:changos).txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another absolutely free",
      :expires_on => "2008 Nov 17"
    )
    test_inbound_txt = lambda do |accepted_time, response_expected|
      phone_number = "16266745901"
      advertiser.publisher.update_attributes! :send_intro_txt => false
      TxtOffer.clear_cache
      Txt.destroy_all
      inbound_txt = nil
      
      assert_difference 'Txt.count', (response_expected ? 1 : 0), accepted_time do 
        inbound_txt = InboundTxt.create_from_gateway!(
          "Message"           => "Sdhtaco plz",
          "AcceptedTime"      => accepted_time,
          "NetworkType"       => "gsm",
          "ServerAddress"     => "898411",
          "OriginatorAddress" => phone_number,
          "Carrier"           => "t-mobile"
        )
      end
      if response_expected
        assert_equal txt_offer, inbound_txt.txt_offer, accepted_time
        txt = Txt.first
        assert_equal inbound_txt, txt.source, accepted_time
        message = "MySDH.com: Buy one taco, get another absolutely free. Exp11/17/08. Std msg chrgs apply. T&Cs at txt411.com"
        assert_equal message, txt.message, accepted_time
      end

      advertiser.publisher.update_attributes! :send_intro_txt => true
      TxtOffer.clear_cache
      Txt.destroy_all
      MobilePhone.find_by_number(phone_number).try(:destroy)
      inbound_txt = nil
      
      assert_difference 'Txt.count', (response_expected ? 2 : 0), accepted_time do 
        inbound_txt = InboundTxt.create_from_gateway!(
          "Message"           => "Sdhtaco plz",
          "AcceptedTime"      => accepted_time,
          "NetworkType"       => "gsm",
          "ServerAddress"     => "898411",
          "OriginatorAddress" => phone_number,
          "Carrier"           => "t-mobile"
        )
      end
      if response_expected
        assert_equal txt_offer, inbound_txt.txt_offer, accepted_time
        txt = Txt.all.detect { |txt| txt.message =~ /coupons to your mobile/i }
        assert_not_nil txt, accepted_time
        assert_equal inbound_txt, txt.source, accepted_time
        txt.destroy
        
        txt = Txt.first
        assert_equal inbound_txt, txt.source, accepted_time
        message = "MySDH.com: Buy one taco, get another absolutely free. Exp11/17/08. Std msg chrgs apply"
        assert_equal message, txt.message, accepted_time
      end
    end
    test_inbound_txt.call "01Aug,07 12:23:56", true
    test_inbound_txt.call "15Nov,08 15:59:59", true
    test_inbound_txt.call "15Nov,08 16:00:00", true
    test_inbound_txt.call "16Nov,08 12:34:56", true
    test_inbound_txt.call "17Nov,08 15:59:59", true
    test_inbound_txt.call "17Nov,08 16:00:00", false
    test_inbound_txt.call "01Aug,09 12:34:56", false
  end
  
  def test_appears_on_with_expires_on
    advertiser = advertisers(:changos)
    
    txt_offer = advertisers(:changos).txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another absolutely free",
      :appears_on => "2008 Nov 16",
      :expires_on => "2008 Nov 17"
    )
    test_inbound_txt = lambda do |accepted_time, response_expected|
      phone_number = "16266745901"
      advertiser.publisher.update_attributes! :send_intro_txt => false
      TxtOffer.clear_cache
      Txt.destroy_all
      inbound_txt = nil
      
      assert_difference 'Txt.count', (response_expected ? 1 : 0), accepted_time do 
        inbound_txt = InboundTxt.create_from_gateway!(
          "Message"           => "Sdhtaco plz",
          "AcceptedTime"      => accepted_time,
          "NetworkType"       => "gsm",
          "ServerAddress"     => "898411",
          "OriginatorAddress" => phone_number,
          "Carrier"           => "t-mobile"
        )
      end
      if response_expected
        assert_equal txt_offer, inbound_txt.txt_offer, accepted_time
        txt = Txt.first
        assert_equal inbound_txt, txt.source, accepted_time
        message = "MySDH.com: Buy one taco, get another absolutely free. Exp11/17/08. Std msg chrgs apply. T&Cs at txt411.com"
        assert_equal message, txt.message, accepted_time
      end

      advertiser.publisher.update_attributes! :send_intro_txt => true
      TxtOffer.clear_cache
      Txt.destroy_all
      MobilePhone.find_by_number(phone_number).try(:destroy)
      inbound_txt = nil
      
      assert_difference 'Txt.count', (response_expected ? 2 : 0), accepted_time do 
        inbound_txt = InboundTxt.create_from_gateway!(
          "Message"           => "Sdhtaco plz",
          "AcceptedTime"      => accepted_time,
          "NetworkType"       => "gsm",
          "ServerAddress"     => "898411",
          "OriginatorAddress" => phone_number,
          "Carrier"           => "t-mobile"
        )
      end
      if response_expected
        assert_equal txt_offer, inbound_txt.txt_offer, accepted_time
        txt = Txt.all.detect { |txt| txt.message =~ /coupons to your mobile/i }
        assert_not_nil txt, accepted_time
        assert_equal inbound_txt, txt.source, accepted_time
        txt.destroy
        
        txt = Txt.first
        assert_equal inbound_txt, txt.source, accepted_time
        message = "MySDH.com: Buy one taco, get another absolutely free. Exp11/17/08. Std msg chrgs apply"
        assert_equal message, txt.message, accepted_time
      end
    end
    test_inbound_txt.call "01Aug,07 12:23:56", false
    test_inbound_txt.call "15Nov,08 15:59:59", false
    test_inbound_txt.call "15Nov,08 16:00:00", true
    test_inbound_txt.call "16Nov,08 12:34:56", true
    test_inbound_txt.call "17Nov,08 15:59:59", true
    test_inbound_txt.call "17Nov,08 16:00:00", false
    test_inbound_txt.call "01Aug,09 12:34:56", false
  end
  
  def test_automatic_keyword_assignment_without_advertiser_txt_keyword_suffix
    txt_offer = advertisers(:changos).txt_offers.create!(
      :short_code => "898411",
      :keyword_prefix => "SDH",
      :assign_keyword => "1",
      :message => "Buy one taco, get another absolutely free"
    )
    assert_equal "898411", txt_offer.short_code
    assert_equal "SDH1", txt_offer.keyword
    assert_equal "Buy one taco, get another absolutely free", txt_offer.message

    txt_offer = advertisers(:changos).txt_offers.new(
      :short_code => "898411",
      :keyword_prefix => "SDH",
      :assign_keyword => "0",
      :message => "Buy one taco, get another absolutely free"
    )
    assert !txt_offer.valid?, "Should not be valid without assign-keyword flag"
    assert txt_offer.errors.on(:keyword), "Should have a keyword error"
  end
  
  def test_automatic_keyword_assignment_with_advertiser_txt_keyword_suffix
    advertiser = advertisers(:changos)
    advertiser.update_attributes! :txt_keyword_prefix => "TACO"
    
    txt_offer = advertiser.txt_offers.new( 
      :short_code => "898411",
      :keyword_prefix => "SDH",
      :assign_keyword => "1",
      :message => "Buy one taco, get another absolutely free"
    )
    assert txt_offer.invalid?, "Should not be valid with invalid keyword prefix"
    assert_match /invalid prefix/, txt_offer.errors.on(:keyword)

    txt_offer = advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword_prefix => "SDHTACO",
      :assign_keyword => "1",
      :message => "Buy one taco, get another absolutely free"
    )
    assert_equal "898411", txt_offer.short_code
    assert_equal "SDHTACO2", txt_offer.keyword
    assert_equal "Buy one taco, get another absolutely free", txt_offer.message

    txt_offer = advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword_prefix => "SDHTACO",
      :assign_keyword => "0",
      :message => "Buy one taco, get another absolutely free"
    )
    assert_equal "898411", txt_offer.short_code
    assert_equal "SDHTACO", txt_offer.keyword
    assert_equal "Buy one taco, get another absolutely free", txt_offer.message
  end
  
  def test_keyword_assembly_without_advertiser_txt_keyword_prefix
    advertiser = advertisers(:changos)
    
    txt_offer = advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword_prefix => "SDH",
      :keyword_suffix => "YUM",
      :assign_keyword => "0",
      :message => "Buy one taco, get another absolutely free"
    )
    assert_equal "898411", txt_offer.short_code
    assert_equal "SDHYUM", txt_offer.keyword
    assert_equal "Buy one taco, get another absolutely free", txt_offer.message

    txt_offer = advertiser.txt_offers.new( 
      :short_code => "898411",
      :keyword_prefix => "SDH",
      :assign_keyword => "0",
      :message => "Buy one taco, get another absolutely free"
    )
    assert txt_offer.invalid?, "Should not be valid without keyword suffix"
    assert_match /is too short/, txt_offer.errors.on(:keyword)
  end

  def test_keyword_assembly_with_advertiser_txt_keyword_prefix
    advertiser =advertisers(:changos)
    advertiser.update_attributes! :txt_keyword_prefix => "TACO"
    
    txt_offer = advertiser.txt_offers.new( 
      :short_code => "898411",
      :keyword_prefix => "SDH",
      :keyword_suffix => "YUM",
      :assign_keyword => "0",
      :message => "Buy one taco, get another absolutely free"
    )
    assert txt_offer.invalid?, "Should not be valid with invalid keyword prefix"
    assert_match /invalid prefix/, txt_offer.errors.on(:keyword)

    txt_offer = advertiser.txt_offers.create!( 
      :short_code => "898411",
      :keyword_prefix => "SDHTACO",
      :assign_keyword => "0",
      :message => "Buy one taco, get another absolutely free"
    )
    assert_equal "898411", txt_offer.short_code
    assert_equal "SDHTACO", txt_offer.keyword
    assert_equal "Buy one taco, get another absolutely free", txt_offer.message
    
    txt_offer = advertiser.txt_offers.create!( 
      :short_code => "898411",
      :keyword_prefix => "SDHTACO",
      :keyword_suffix => "YUM",
      :assign_keyword => "0",
      :message => "Buy one taco, get another absolutely free"
    )
    assert_equal "898411", txt_offer.short_code
    assert_equal "SDHTACOYUM", txt_offer.keyword
    assert_equal "Buy one taco, get another absolutely free", txt_offer.message
  end

  def test_max_message_size
    expected_size = lambda do |header, expires, send_intro_txt|
      header ||= "TXT411"
      header  += ": "
      footer = expires ? ". Exp00/00/00" : ""
      tandcs = send_intro_txt ? ". Std msg chrgs apply" : ". Std msg chrgs apply. T&Cs at txt411.com"
      160 - header.size - footer.size - tandcs.size
    end

    advertiser = advertisers(:changos)
    
    txt_offer = advertiser.txt_offers.build
    assert_equal expected_size.call("MySDH.com", false, false), txt_offer.max_message_size
    txt_offer = advertiser.txt_offers.build(:expires_on => "Nov 01 2008")
    assert_equal expected_size.call("MySDH.com", true, false), txt_offer.max_message_size

    advertiser.publisher.update_attributes! :brand_txt_header => nil
    txt_offer = advertiser.reload.txt_offers.build
    assert_equal expected_size.call(nil, false, false), txt_offer.max_message_size
    txt_offer = advertiser.txt_offers.build(:expires_on => "Nov 01 2008")
    assert_equal expected_size.call(nil, true, false), txt_offer.max_message_size

    advertiser.publisher.update_attributes! :send_intro_txt => true
    txt_offer = advertiser.reload.txt_offers.build
    assert_equal expected_size.call(nil, false, true), txt_offer.max_message_size
    txt_offer = advertiser.txt_offers.build(:expires_on => "Nov 01 2008")
    assert_equal expected_size.call(nil, true, true), txt_offer.max_message_size

    advertiser.publisher.update_attributes! :brand_txt_header => "MySDH.com"
    txt_offer = advertiser.reload.txt_offers.build
    assert_equal expected_size.call("MySDH.com", false, true), txt_offer.max_message_size
    txt_offer = advertiser.txt_offers.build(:expires_on => "Nov 01 2008")
    assert_equal expected_size.call("MySDH.com", true, true), txt_offer.max_message_size
  end

  def test_full_message_head
    advertiser = advertisers(:changos)
    txt_offer = advertiser.txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another absolutely free"
    )
    assert_match /\AMySDH.com:/, txt_offer.full_message, "Message head with publisher brand header"

    advertiser.publisher.update_attributes! :brand_txt_header => nil
    assert_match /\TXT411:/, txt_offer.reload.full_message, "Message head without publisher brand header"
  end
  
  def test_full_message_foot
    txt_offer = advertisers(:changos).txt_offers.build(
      :short_code => "898411",
      :keyword => "taco",
      :message => "Buy one taco, get another absolutely free"
    )
    assert_no_match /2008/, txt_offer.full_message, "Full message with no dates"

    txt_offer.appears_on = "Oct 15, 2008"
    assert_no_match /2008/, txt_offer.full_message, "Full message with no expiration date"

    txt_offer.expires_on = "Jan 2, 2008"
    assert_match "Exp01/02/08", txt_offer.full_message, "Full message with expiration date"
    
    txt_offer.expires_on = "Nov 30, 2008"
    assert_match "Exp11/30/08", txt_offer.full_message, "Full message with expiration date"
  end
  
  def test_no_intro_txt_sent_if_no_instances
    TxtOffer.destroy_all
    TxtOffer.clear_cache
    Txt.destroy_all

    advertiser = advertisers(:changos)
    advertiser.publisher.update_attributes! :send_intro_txt => true
    
    assert_difference 'Txt.count', 0 do 
      inbound_txt = InboundTxt.create_from_gateway!(
        "Message"           => "Sdhtaco plz",
        "AcceptedTime"      => "27Nov,08 11:22:33",
        "NetworkType"       => "gsm",
        "ServerAddress"     => "898411",
        "OriginatorAddress" => "16266745901",
        "Carrier"           => "t-mobile"
      )
    end
  end
  
  def test_message_length_validation
    advertiser = advertisers(:changos)
    txt_offer = advertiser.txt_offers.build(:short_code => "898411", :keyword => "SDHTACOS", :expires_on => "Nov 01 2008")
    max_length = 160 - "MySDH.com: . Exp11/01/08. T&Cs at txt411.com. Std msg chrgs apply".length
    
    txt_offer.message = "x"*(max_length - 1)
    assert txt_offer.valid?, "Should be valid under max message size"
    
    txt_offer.message = "x"*(max_length)
    assert txt_offer.valid?, "Should be valid at max message size"
    
    txt_offer.message = "x"*(max_length + 1)
    assert !txt_offer.valid?, "Should not be valid over max message size"
    assert_match /too long/i, txt_offer.errors.on(:message).to_s
  end
  
  def test_active_limit_validation_on_create_with_nil_dates
    advertiser = advertisers(:changos)

    with_publisher_or_advertiser_limit(advertiser, nil) do |limits|
      advertiser.txt_offers.destroy_all
      build_txt_offer(advertiser, "SDH", 1).save!
      build_txt_offer(advertiser, "SDH", 2).save!
      build_txt_offer(advertiser, "SDH", 3).save!
      build_txt_offer(advertiser, "SDH", 4).save!
      build_txt_offer(advertiser, "SDH", 5).save!
    end
    
    with_publisher_or_advertiser_limit(advertiser, 3) do |limits|
      advertiser.txt_offers.destroy_all
      build_txt_offer(advertiser, "SDH", 1).save!
      build_txt_offer(advertiser, "SDH", 2).save!
      build_txt_offer(advertiser, "SDH", 3).save!
    
      txt_offer = build_txt_offer(advertiser, "SDH", 4)
      assert !txt_offer.valid?, "TXT offer should not be valid with 3 existing active TXT offers and #{limits}"
      assert_match(/more than 3 active/, txt_offer.errors.on_base, "Error message for #{limits}")
    end
  end

  def test_active_limit_validation_on_create_with_given_dates
    ActiveSupport::TimeWithZone.any_instance.stubs(:to_date).returns(Date.new(2008, 10, 1))

    advertiser = advertisers(:changos)
    with_publisher_or_advertiser_limit(advertiser, 3) do |limits|
      advertiser.txt_offers.destroy_all
      build_txt_offer(advertiser, "SDH", 1, "Nov 01, 2008", "Nov 30, 2008").save!
      build_txt_offer(advertiser, "SDH", 2, "Nov 15, 2008", "Dec 15, 2008").save!
      build_txt_offer(advertiser, "SDH", 3, "Nov 17, 2008", "Nov 28, 2008").save!

      txt_offer = build_txt_offer(advertiser, "SDH", 4, "Nov 10, 2008", "Nov 20, 2008")
      assert !txt_offer.valid?, "TXT offer should not be valid with 3 existing active TXT offers and #{limits}"
      assert_match(/more than 3 active/, txt_offer.errors.on_base, "Error message with #{limits}")
    end
  end

  def test_active_limit_validation_on_update_with_given_dates
    ActiveSupport::TimeWithZone.any_instance.stubs(:to_date).returns(Date.new(2008, 10, 1))

    advertiser = advertisers(:changos)
    
    with_publisher_or_advertiser_limit(advertiser, 3) do |limits|
      advertiser.txt_offers.destroy_all
      build_txt_offer(advertiser, "SDH", 1, "Nov 01, 2008", "Nov 30, 2008").save!
      build_txt_offer(advertiser, "SDH", 2, "Nov 15, 2008", "Dec 15, 2008").save!
      build_txt_offer(advertiser, "SDH", 3, "Nov 17, 2008", "Nov 28, 2008").save!
      build_txt_offer(advertiser, "SDH", 4, "Nov 01, 2008", "Nov 16, 2008").save!

      txt_offer = TxtOffer.find_by_keyword("SDHTACO4")
      txt_offer.expires_on = "Nov 20, 2008"
      assert !txt_offer.valid?, "TXT offer should not be valid with 3 existing active TXT offers and #{limits}"
      assert_match(/more than 3 active/, txt_offer.errors.on_base, "Error message with #{limits}")
    end
  end
  
  def test_active_limit_validation_with_zero_limit
    ActiveSupport::TimeWithZone.any_instance.stubs(:to_date).returns(Date.new(2008, 10, 1))

    advertiser = advertisers(:changos)
    with_publisher_or_advertiser_limit(advertiser, 0) do |limits|
      txt_offer = build_txt_offer(advertiser, "SDH", 1)
      assert !txt_offer.valid?, "TXT offer should not be valid with #{limits}"
      assert_match /any active/, txt_offer.errors.on_base, "Error message with #{limits}"
    
      txt_offer.appears_on = "Nov 01, 2008"
      assert !txt_offer.valid?, "TXT offer should not be valid with #{limits}"
      assert_match /any active/, txt_offer.errors.on_base, "Error message with #{limits}"

      txt_offer.expires_on = "Nov 30, 2008"
      assert !txt_offer.valid?, "TXT offer should not be valid with #{limits}"
      assert_match /any active/, txt_offer.errors.on_base, "Error message"

      txt_offer.appears_on = nil
      assert !txt_offer.valid?, "TXT offer should not be valid with #{limits}"
      assert_match /any active/, txt_offer.errors.on_base, "Error message with #{limits}"
    end
  end

  def test_active_limit_validation_ignores_deleted_txt_offer
    advertiser = advertisers(:changos)
    with_publisher_or_advertiser_limit(advertiser, 3) do |limits|
      advertiser.txt_offers.destroy_all
      build_txt_offer(advertiser, "SDH", 1).save!
      build_txt_offer(advertiser, "SDH", 2).save!
      build_txt_offer(advertiser, "SDH", 3, nil, nil, :deleted => true).save!

      txt_offer = build_txt_offer(advertiser, "SDH", 4)
      assert txt_offer.save, "TXT offer should be valid with 2 existing active and 1 deleted TXT offer and #{limits}"
    
      txt_offer = build_txt_offer(advertiser, "SDH", 4)
      assert !txt_offer.valid?, "TXT offer should not be valid with 3 existing active TXT offers and #{limits}"
      assert_match /more than 3 active/, txt_offer.errors.on_base, "Error message with #{limits}"
    end
  end

  def test_validation_of_immutable_attributes
    advertiser = advertisers(:changos)
    
    txt_offer = build_txt_offer(advertiser, "SDH", 1)
    txt_offer.save!
    txt_offer.advertiser = advertisers(:di_milles)
    assert txt_offer.invalid?, "Should not be valid with modified advertiser ID"
    assert_match /cannot be changed/, txt_offer.errors.on(:advertiser_id)

    txt_offer = build_txt_offer(advertiser, "SDH", 2)
    txt_offer.save!
    txt_offer.short_code = "898444"
    assert txt_offer.invalid?, "Should not be valid with modified short code"
    assert_match /cannot be changed/, txt_offer.errors.on(:short_code)

    txt_offer = build_txt_offer(advertiser, "SDH", 3)
    txt_offer.save!
    txt_offer.keyword = "SDHFOO"
    assert txt_offer.invalid?, "Should not be valid with modified keyword"
    assert_match /cannot be changed/, txt_offer.errors.on(:keyword)
  end
  
  def test_validation_of_keyword_without_advertiser_keyword_prefix
    advertiser = advertisers(:changos)
    advertiser.publisher.update_attributes! :txt_keyword_prefix => "XXX"
    
    txt_offer = advertiser.txt_offers.new(:short_code => "898411", :keyword => "TACO", :message => "Buy one taco, get one free")
    assert txt_offer.invalid?, "Should not be valid with invalid keyword prefix"
    assert_match /invalid prefix/, txt_offer.errors.on(:keyword)

    txt_offer = advertiser.txt_offers.new(:short_code => "898411", :keyword => "XXX", :message => "Buy one taco, get one free")
    assert txt_offer.invalid?, "Should not be valid with valid keyword prefix but without suffix"
    assert_match /too short/, txt_offer.errors.on(:keyword)

    txt_offer = advertiser.txt_offers.new(:short_code => "898411", :keyword => "XXXTACO", :message => "Buy one taco, get one free")
    assert txt_offer.valid?, "Should be valid with valid keyword prefix and suffix"

    advertiser.publisher.update_attributes! :txt_keyword_prefix => nil
    advertiser.reload

    txt_offer = advertiser.txt_offers.new(:short_code => "898411", :keyword => "TACO", :message => "Buy one taco, get one free")
    assert txt_offer.invalid?, "Should not be valid with invalid keyword prefix"
    assert_match /invalid prefix/, txt_offer.errors.on(:keyword)
  end
  
  def test_validation_of_keyword_with_advertiser_keyword_prefix
    advertiser = advertisers(:changos)
    advertiser.update_attributes! :txt_keyword_prefix => "YYY"
    advertiser.publisher.update_attributes! :txt_keyword_prefix => "XXX"
    
    txt_offer = advertiser.txt_offers.new(:short_code => "898411", :keyword => "XXX", :message => "Buy one taco, get one free")
    assert txt_offer.invalid?, "Should not be valid with invalid keyword prefix"
    assert_match /invalid prefix/, txt_offer.errors.on(:keyword)

    txt_offer = advertiser.txt_offers.new(:short_code => "898411", :keyword => "XXXYYY", :message => "Buy one taco, get one free")
    assert txt_offer.valid?, "Should be valid with valid keyword prefix but without suffix"

    txt_offer = advertiser.txt_offers.new(:short_code => "898411", :keyword => "XXXYYYTACO", :message => "Buy one taco, get one free")
    assert txt_offer.valid?, "Should be valid with valid keyword prefix and suffix"

    advertiser.publisher.update_attributes! :txt_keyword_prefix => nil
    advertiser.reload

    txt_offer = advertiser.txt_offers.new(:short_code => "898411", :keyword => "YYY", :message => "Buy one taco, get one free")
    assert txt_offer.invalid?, "Should not be valid with invalid keyword prefix"
    assert_match /invalid prefix/, txt_offer.errors.on(:keyword)

    txt_offer = advertiser.txt_offers.new(:short_code => "898411", :keyword => "YYYTACO", :message => "Buy one taco, get one free")
    assert txt_offer.invalid?, "Should not be valid with invalid keyword prefix"
    assert_match /invalid prefix/, txt_offer.errors.on(:keyword)
  end
  
  def test_handle_inbound_txt_while_not_deleted
    txt_offer = advertisers(:changos).txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another free"
    )
    inbound_txt = mock("inbound_txt", :server_address => "898411", :keyword => "SDHTACO")

    TxtOffer.clear_cache
    TxtOffer.any_instance.expects(:respond_to)
    TxtOffer.handle_inbound_txt(inbound_txt)
  end

  def test_handle_inbound_txt_while_deleted
    txt_offer = advertisers(:changos).txt_offers.create!(
      :short_code => "898411",
      :keyword => "sdhtaco",
      :message => "Buy one taco, get another free",
      :deleted => true
    )
    inbound_txt = mock("inbound_txt", :server_address => "898411", :keyword => "SDHTACO")

    TxtOffer.clear_cache
    TxtOffer.any_instance.expects(:respond_to).never
    TxtOffer.handle_inbound_txt(inbound_txt)
  end

  def test_label_validation
    txt_offer_1 = advertisers(:el_greco).txt_offers.create!(:keyword => "SDH1", :message => "Offer One", :label => "42")
    
    advertiser = advertisers(:changos)
    txt_offer_2 = advertiser.txt_offers.build(:keyword => "SDH2", :message => "Offer Two", :label => "42")
    assert txt_offer_2.valid?, "Should be valid with duplicate label but another advertiser"
    txt_offer_2.save!
    
    txt_offer_3 = advertiser.txt_offers.build(:keyword => "SDH3", :message => "Offer Tre", :label => "43")
    assert txt_offer_3.valid?, "Should be valid with unique label"
    
    txt_offer_3.label = "42"
    assert txt_offer_3.invalid?, "Should not be valid with duplicate label for the same advertiser"
  end
  
  private
  
  def build_txt_offer(advertiser, prefix, i, appears_on=nil, expires_on=nil, options={})
    advertiser.txt_offers.build({
      :short_code => "898411", :keyword => "#{prefix}TACO#{i}", :message => "Message #{i}",
      :appears_on => appears_on, :expires_on => expires_on
    }.merge(options))
  end
  
  def with_publisher_or_advertiser_limit(advertiser, limit)
    publisher = advertiser.publisher
    
    advertiser.reload.update_attributes! :active_txt_coupon_limit => limit
    publisher.reload.update_attributes!  :active_txt_coupon_limit => nil
    yield "advertiser limit #{limit}"

    advertiser.reload.update_attributes! :active_txt_coupon_limit => nil
    publisher.reload.update_attributes!  :active_txt_coupon_limit => limit
    yield "publisher limit #{limit}"
    
    advertiser.reload.update_attributes! :active_txt_coupon_limit => limit
    publisher.reload.update_attributes!  :active_txt_coupon_limit => limit
    yield "advertiser and publisher limit #{limit}"
  end
end

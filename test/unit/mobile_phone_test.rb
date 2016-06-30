require File.dirname(__FILE__) + "/../test_helper"

class MobilePhoneTest < ActiveSupport::TestCase
  def test_create
    mobile_phone = MobilePhone.create!(:number => "12123459999")
    assert !mobile_phone.opt_out?, "Should default to opt-in"
    assert !mobile_phone.intro_txt_sent?, "Should default to intro txt not sent"
  end
  
  def test_validation
    assert(!MobilePhone.create.valid?, "No number should be invaild")
    assert(!MobilePhone.create(:number => "411").valid?, "short number should be invaild")
    assert(!MobilePhone.create(:number => "121234599990").valid?, "long number should be invaild")
  end
  
  def test_number_as_entered
    mobile_phone = MobilePhone.create(:number => "(605) 162-9100")
    assert_equal("(605) 162-9100", mobile_phone.number_as_entered, "(605) 162-9100 as entered")
  end
  
  def test_normalize_number
    mobile_phone = MobilePhone.new(:number => "(605) 162-9100")
    assert mobile_phone.valid?
    assert_equal("16051629100", mobile_phone.number, "mobile number")

    mobile_phone = MobilePhone.new(:number => "1 (605) 162-9100")
    assert mobile_phone.valid?
    assert_equal("16051629100", mobile_phone.number, "mobile number")

    mobile_phone = MobilePhone.new(:number => "6051629100")
    assert mobile_phone.valid?
    assert_equal("16051629100", mobile_phone.number, "mobile number")

    mobile_phone = MobilePhone.new(:number => "16051629100")
    assert mobile_phone.valid?
    assert_equal("16051629100", mobile_phone.number, "mobile number")
  end
  
  def test_redundant_opt_out
    count = MobilePhone.count
    MobilePhone.create!(:number => "(605) 162-9100")
    mobile_phone = MobilePhone.create(:number => "(605) 162-9100")
    assert(!mobile_phone.errors.on(:opt_out), "Shouldn't allow multiple opt-outs")
    
    assert_equal(count + 1, MobilePhone.count, "Should not create number a second time")
  end
  
  def test_from_params_with_valid_number
    assert !MobilePhone.find_by_number("12125551212")
    assert !MobilePhone.number_opted_out?("12125551212")

    assert_difference 'MobilePhone.count' do
      assert(mobile_phone = MobilePhone.from_params(:number => "212-555-1212", :opt_out => true))
      assert mobile_phone.valid?
      assert MobilePhone.number_opted_out?("12125551212")
      assert MobilePhone.number_opted_out?("212-555-1212")
    end

    assert_no_difference 'MobilePhone.count' do
      assert(mobile_phone = MobilePhone.from_params(:number => "212-555-1212", :opt_out => true))
      assert mobile_phone.valid?
      assert MobilePhone.number_opted_out?("12125551212")
      assert MobilePhone.number_opted_out?("212-555-1212")
    end

    assert_no_difference 'MobilePhone.count' do
      assert(mobile_phone = MobilePhone.from_params(:number => "212-555-1212", :opt_out => false))
      assert mobile_phone.valid?
      assert !MobilePhone.number_opted_out?("12125551212")
      assert !MobilePhone.number_opted_out?("212-555-1212")
    end

    assert_no_difference 'MobilePhone.count' do
      assert(mobile_phone = MobilePhone.from_params(:number => "212-555-1212", :opt_out => false))
      assert mobile_phone.valid?
      assert !MobilePhone.number_opted_out?("12125551212")
      assert !MobilePhone.number_opted_out?("212-555-1212")
    end

    assert_no_difference 'MobilePhone.count' do
      assert(mobile_phone = MobilePhone.from_params(:number => "212-555-1212", :opt_out => true))
      assert mobile_phone.valid?
      assert MobilePhone.number_opted_out?("12125551212")
      assert MobilePhone.number_opted_out?("212-555-1212")
    end
  end
  
  def test_from_params_with_invalid_number
    assert_no_difference 'MobilePhone.count' do
      assert(mobile_phone = MobilePhone.from_params(:number => "212-555", :opt_out => true))
      assert !mobile_phone.valid?
      assert mobile_phone.errors.on(:number)
    end
  end
    
  def test_send_txt_without_intro_txt_to_valid_number_opted_in
    assert !MobilePhone.find_by_number("12125551212")
    assert !MobilePhone.number_opted_out?("12125551212")
    Txt.destroy_all
    #
    # Should create one TXT on first send.
    #
    assert MobilePhone.send_txt_to_number("12125551212", "This is test 1")
    assert_equal 1, Txt.count
    assert_not_nil Txt.all.detect { |txt| txt.mobile_number = "12125551212" && txt.message =~ /This is test 1/ }
    #
    # Should create one TXT on subsequent sends.
    #
    assert MobilePhone.send_txt_to_number("12125551212", "This is test 2")
    assert_equal 2, Txt.count
    assert_not_nil Txt.all.detect { |txt| txt.mobile_number = "12125551212" && txt.message =~ /This is test 2/ }
  end

  def test_send_txt_with_intro_txt_to_valid_number_opted_in
    assert !MobilePhone.find_by_number("12125551212")
    assert !MobilePhone.number_opted_out?("12125551212")
    Txt.destroy_all

    assert MobilePhone.send_txt_to_number("12125551212", "This is test 1", :send_intro_txt => true)
    assert_equal 2, Txt.count, "Should create two text messages on first send"
    assert_not_nil Txt.all.detect { |txt| txt.mobile_number = "12125551212" && txt.message =~ /Coupons to your mobile/ }
    assert_not_nil Txt.all.detect { |txt| txt.mobile_number = "12125551212" && txt.message =~ /This is test 1/ }

    assert MobilePhone.send_txt_to_number("12125551212", "This is test 2")
    assert_equal 3, Txt.count, "Should create one text message on subsequent send"
    assert_not_nil Txt.all.detect { |txt| txt.mobile_number = "12125551212" && txt.message =~ /This is test 2/ }
  end

  def test_send_txt_to_valid_number_opted_out
    assert MobilePhone.from_params(:number => "212-555-1212", :opt_out => true)
    assert MobilePhone.number_opted_out?("212-555-1212")
    assert_no_difference 'Txt.count' do
      assert !MobilePhone.send_txt_to_number("212-555-1212", "This is test 1")
      assert !MobilePhone.send_txt_to_number("212-555-1212", "This is test 2", :send_intro_txt => true)
    end
  end
  
  def test_send_txt_to_invalid_number
    assert_no_difference 'Txt.count' do
      assert !MobilePhone.send_txt_to_number("12345", "This is test 1")
      assert !MobilePhone.send_txt_to_number("12345", "This is test 2", :send_intro_txt => true)
    end
  end

  def test_send_txt_without_intro_txt_with_head_and_foot
    assert_message = lambda do |parts, message|
      head, body, foot = parts
      Txt.destroy_all
      assert_difference 'Txt.count', 1, "TXT count for #{head}/#{body}" do
        MobilePhone.send_txt_to_number('212-555-1212', body, :head => head, :foot => foot)
      end
      txt = Txt.first
      assert_equal "12125551212", txt.mobile_number, "TXT mobile number for #{head}/#{body}"
      assert_equal message, txt.message, "TXT message for #{head}/#{body}"
      if body.size > 160
        assert_equal 160, txt.message.length, "TXT message length for #{head}/#{body}"
      end
    end
    
    parts = ["MySDH.com", "TXT 1", "Exp01/02/03"]
    assert_message.call parts, "MySDH.com: TXT 1. Exp01/02/03. Std msg chrgs apply. T&Cs at txt411.com"
    parts = ["MySDH.com", " TXT 1. ", "Exp01/02/03"]
    assert_message.call parts, "MySDH.com: TXT 1. Exp01/02/03. Std msg chrgs apply. T&Cs at txt411.com"
    
    parts = [nil, " TXT 2", nil]
    assert_message.call parts, "TXT411: TXT 2. Std msg chrgs apply. T&Cs at txt411.com"
    parts = [nil, " TXT 2. ", nil]
    assert_message.call parts, "TXT411: TXT 2. Std msg chrgs apply. T&Cs at txt411.com"
    
    parts = ["MySDH.com", "TXT "+"3"*200, "Exp01/02/03"]
    assert_message.call parts, "MySDH.com: TXT "+"3"*89 + "... Exp01/02/03. Std msg chrgs apply. T&Cs at txt411.com"
    parts = ["MySDH.com", " TXT "+"3"*200+". ", "Exp01/02/03"]
    assert_message.call parts, "MySDH.com: TXT "+"3"*89 + "... Exp01/02/03. Std msg chrgs apply. T&Cs at txt411.com"
    
    parts = [nil, "TXT "+"4"*200, nil]
    assert_message.call parts, "TXT411: TXT "+"4"*105 + "... Std msg chrgs apply. T&Cs at txt411.com"
    parts = [nil, " TXT "+"4"*200+". ", nil]
    assert_message.call parts, "TXT411: TXT "+"4"*105 + "... Std msg chrgs apply. T&Cs at txt411.com"
  end

  def test_send_txt_with_intro_txt_with_head_and_foot
    assert_message = lambda do |parts, message|
      head, body, foot = parts
      Txt.destroy_all
      MobilePhone.destroy_all
      
      assert_difference 'Txt.count', 2, "TXT count for #{head}/#{body}" do
        MobilePhone.send_txt_to_number('212-555-1212', body, :head => head, :foot => foot, :send_intro_txt => true)
      end
      txt = Txt.all.first
      assert_equal "12125551212", txt.mobile_number, "TXT mobile number for #{head}/#{body}"
      assert_match /\A#{head.blank? ? "TXT411" : head}: /, txt.message
      assert_match /coupons to your mobile.*for help.*msg chrgs apply/i, txt.message
      
      txt = Txt.all.second
      assert_equal "12125551212", txt.mobile_number, "TXT mobile number for #{head}/#{body}"
      assert_equal message, txt.message, "TXT message for #{head}/#{body}"
      if body.size > 160
        assert_equal 160, txt.message.length, "TXT message length for #{head}/#{body}"
      end
    end
    
    parts = ["MySDH.com", "TXT 1", "Exp01/02/03"]
    assert_message.call parts, "MySDH.com: TXT 1. Exp01/02/03. Std msg chrgs apply"
    parts = ["MySDH.com", " TXT 1. ", "Exp01/02/03"]
    assert_message.call parts, "MySDH.com: TXT 1. Exp01/02/03. Std msg chrgs apply"
    
    parts = [nil, " TXT 2", nil]
    assert_message.call parts, "TXT411: TXT 2. Std msg chrgs apply"
    parts = [nil, " TXT 2. ", nil]
    assert_message.call parts, "TXT411: TXT 2. Std msg chrgs apply"
    
    parts = ["MySDH.com", "TXT "+"3"*200, "Exp01/02/03"]
    assert_message.call parts, "MySDH.com: TXT "+"3"*109 + "... Exp01/02/03. Std msg chrgs apply"
    parts = ["MySDH.com", " TXT "+"3"*200+". ", "Exp01/02/03"]
    assert_message.call parts, "MySDH.com: TXT "+"3"*109 + "... Exp01/02/03. Std msg chrgs apply"
    
    parts = [nil, "TXT "+"4"*200, nil]
    assert_message.call parts, "TXT411: TXT "+"4"*125 + "... Std msg chrgs apply"
    parts = [nil, " TXT "+"4"*200+". ", nil]
    assert_message.call parts, "TXT411: TXT "+"4"*125 + "... Std msg chrgs apply"
  end
  
  def test_max_body_length
    length = 160 - "TXT411: . Std msg chrgs apply. T&Cs at txt411.com".length
    assert_equal length, MobilePhone.max_body_length
    
    length = 160 - "TXT411: . Std msg chrgs apply".length
    assert_equal length, MobilePhone.max_body_length(:send_intro_txt => true)
    
    length = 160 - "MySDH.com: . Std msg chrgs apply. T&Cs at txt411.com".length
    assert_equal length, MobilePhone.max_body_length(:head => "MySDH.com")
    
    length = 160 - "MySDH.com: . Std msg chrgs apply".length
    assert_equal length, MobilePhone.max_body_length(:head => "MySDH.com", :send_intro_txt => true)
    
    length = 160 - "MySDH.com: . Exp01/02/03. Std msg chrgs apply. T&Cs at txt411.com".length
    assert_equal length, MobilePhone.max_body_length(:head => "MySDH.com", :foot => "Exp01/02/03")
    
    length = 160 - "MySDH.com: . Exp01/02/03. Std msg chrgs apply".length
    assert_equal length, MobilePhone.max_body_length(:head => "MySDH.com", :foot => "Exp01/02/03", :send_intro_txt => true)
  end
end

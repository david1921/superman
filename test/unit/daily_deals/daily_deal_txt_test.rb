require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealTxtTest < ActiveSupport::TestCase
  test "handle_inbound_txt with no subkeyword" do
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD", :keyword => "BBD", :subkeyword => nil)
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Send BBD R <8-digits> to redeem, BBD V <8-digits> to validate daily-deal voucher. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
  end

  test "handle_inbound_txt with subkeyword matching valid serial number" do
    ddp = Factory(:captured_daily_deal_purchase)
    ddc = ddp.daily_deal_certificates.create!(:redeemer_name => ddp.consumer.name)
    digits = ddc.serial_number.gsub(/\D/, '')
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD #{digits}", :keyword => "BBD", :subkeyword => digits)
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Voucher #{ddc.serial_number} is VALID for $30.00 and now marked REDEEMED. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
    assert ddc.reload.redeemed?, "Certificate should be marked redeemed"
  end

  test "handle_inbound_txt with subkeyword matching invalid serial number" do
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD 12345678", :keyword => "BBD", :subkeyword => "12345678")
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Voucher 1234-5678 is NOT VALID. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
  end

  test "handle_inbound_txt with subkeyword matching redeemed serial number" do
    ddp = Factory(:captured_daily_deal_purchase)
    ddc = ddp.daily_deal_certificates.create!(
      :redeemer_name => ddp.consumer.name,
      :redeemed_at => Time.zone.now,
      :status => "redeemed"
    )
    digits = ddc.serial_number.gsub(/\D/, '')
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD #{digits}", :keyword => "BBD", :subkeyword => digits)
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Voucher #{ddc.serial_number} is ALREADY REDEEMED. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
    assert ddc.reload.redeemed?, "Certificate should be marked redeemed"
  end

  test "handle_inbound_txt with R subkeyword and parameter matching valid serial number" do
    ddp = Factory(:captured_daily_deal_purchase)
    ddc = ddp.daily_deal_certificates.create!(:redeemer_name => ddp.consumer.name)
    digits = ddc.serial_number.gsub(/\D/, '')
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD R #{digits}", :keyword => "BBD", :subkeyword => "R")
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Voucher #{ddc.serial_number} is VALID for $30.00 and now marked REDEEMED. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
    assert ddc.reload.redeemed?, "Certificate should be marked redeemed"
  end

  test "handle_inbound_txt with R subkeyword and parameter matching invalid serial number" do
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD R 12345678", :keyword => "BBD", :subkeyword => "R")
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Voucher 1234-5678 is NOT VALID. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
  end

  test "handle_inbound_txt with R subkeyword and parameter matching redeemed serial number" do
    ddp = Factory(:captured_daily_deal_purchase)
    ddc = ddp.daily_deal_certificates.create!(
      :redeemer_name => ddp.consumer.name,
      :redeemed_at => Time.zone.now,
      :status => "redeemed"
    )
    digits = ddc.serial_number.gsub(/\D/, '')
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD R #{digits}", :keyword => "BBD", :subkeyword => "R")
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Voucher #{ddc.serial_number} is ALREADY REDEEMED. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
  end

  test "handle_inbound_txt with V subkeyword and parameter matching valid serial number" do
    ddp = Factory(:captured_daily_deal_purchase)
    ddc = ddp.daily_deal_certificates.create!(:redeemer_name => ddp.consumer.name)
    digits = ddc.serial_number.gsub(/\D/, '')
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD V #{digits}", :keyword => "BBD", :subkeyword => "V")
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Voucher #{ddc.serial_number} is VALID for $30.00. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
    assert !ddc.reload.redeemed?, "Certificate should not be marked redeemed"
  end

  test "handle_inbound_txt with V subkeyword and parameter matching invalid serial number" do
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD V 12345678", :keyword => "BBD", :subkeyword => "V")
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Voucher 1234-5678 is NOT VALID. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
  end

  test "handle_inbound_txt with V subkeyword and parameter matching redeemed serial number" do
    ddp = Factory(:captured_daily_deal_purchase)
    ddc = ddp.daily_deal_certificates.create!(
      :redeemer_name => ddp.consumer.name,
      :redeemed_at => Time.zone.now,
      :status => "redeemed"
    )
    digits = ddc.serial_number.gsub(/\D/, '')
    inbound_txt = Factory.build(:inbound_txt, :message => "BBD V #{digits}", :keyword => "BBD", :subkeyword => "V")
    inbound_txt.stubs(:create_reply_txt)
    
    assert_difference 'Txt.count' do
      DailyDealTxt.handle_inbound_txt inbound_txt
    end
    expected = "TXT411: Voucher #{ddc.serial_number} is ALREADY REDEEMED. Std msg chrgs apply. T&Cs at txt411.com"
    assert_equal expected, Txt.last.message
  end
end

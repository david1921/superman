require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::QrCodeTest < ActiveSupport::TestCase
  
  context "Daily deal QR codes" do
    
    setup do
      @daily_deal = Factory :daily_deal
    end
    
    context "#qr_code_data" do
      
      should "return a URL of the form HTTP://FNDG.ME/:id, where :id is the deal ID " +
             "encoded in base36, when there is no qr_code_host set" do
        assert @daily_deal.publisher.qr_code_host.blank?
        assert @daily_deal.publishing_group.qr_code_host.blank?
        assert_equal "HTTP://FNDG.ME/D/#{@daily_deal.id.to_s(36)}".upcase, @daily_deal.qr_code_data
      end
      
      should "use Publisher#qr_code_host, when set and PublishingGroup#qr_code_host is blank" do
        assert @daily_deal.publishing_group.qr_code_host.blank?
        @daily_deal.publisher.qr_code_host = "foo.bar"
        assert_equal "HTTP://FOO.BAR/D/#{@daily_deal.id.to_s(36)}".upcase, @daily_deal.qr_code_data
      end
      
      should "use Publisher#qr_code_host, when set and PublishingGroup#qr_code_host is set" do
        @daily_deal.publishing_group.qr_code_host = "pg.foo.bar"
        @daily_deal.publisher.qr_code_host = "foo.bar"
        assert_equal "HTTP://FOO.BAR/D/#{@daily_deal.id.to_s(36)}".upcase, @daily_deal.qr_code_data
      end
      
      should "use PublishingGroup#qr_code_host when set, if Publisher#qr_code_host is blank" do
        @daily_deal.publishing_group.qr_code_host = "pg.foo.bar"
        assert @daily_deal.publisher.qr_code_host.blank?
        assert_equal "HTTP://PG.FOO.BAR/D/#{@daily_deal.id.to_s(36)}".upcase, @daily_deal.qr_code_data
      end
    end
     
    context "#voucher_has_qr_code" do
      
      should "default to false" do
        daily_deal = Factory(:daily_deal)
        assert_equal false, daily_deal.voucher_has_qr_code
        assert_equal false, daily_deal.voucher_has_qr_code?
        daily_deal.reload
        assert_equal false, daily_deal.voucher_has_qr_code
        assert_equal false, daily_deal.voucher_has_qr_code?
      end

      context "honor PublishingGroup default" do
        should "default to true" do
          publishing_group = Factory(:publishing_group, :voucher_has_qr_code_default => true)
          publisher = Factory(:publisher, :publishing_group => publishing_group)
          daily_deal = Factory(:daily_deal, :publisher => publisher)
          assert_equal true, daily_deal.voucher_has_qr_code
          assert_equal true, daily_deal.voucher_has_qr_code?
          daily_deal.reload
          assert_equal true, daily_deal.voucher_has_qr_code
          assert_equal true, daily_deal.voucher_has_qr_code?
        end

        should "default to false" do
          publishing_group = Factory(:publishing_group, :voucher_has_qr_code_default => false)
          publisher = Factory(:publisher, :publishing_group => publishing_group)
          daily_deal = Factory(:daily_deal, :publisher => publisher)
          assert_equal false, daily_deal.voucher_has_qr_code
          assert_equal false, daily_deal.voucher_has_qr_code?
          daily_deal.reload
          assert_equal false, daily_deal.voucher_has_qr_code
          assert_equal false, daily_deal.voucher_has_qr_code?
        end
      end
    end
  end  
end

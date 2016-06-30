require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::BarCodeTest

class DailyDeals::BarCodeTest < ActiveSupport::TestCase
   test "import bar codes" do
    daily_deal = Factory(:daily_deal)
    assert_equal 0, daily_deal.bar_codes.count
    
    daily_deal.import_bar_codes StringIO.new("01234\n56789\n"), true, false
    assert_equal 2, daily_deal.bar_codes.count
    assert_equal %w{ 01234 56789 }, daily_deal.bar_codes.map(&:code)
    assert_equal [false] * 2, daily_deal.bar_codes.map(&:assigned)
    
    daily_deal.import_bar_codes StringIO.new("abcde\nfghij\n"), false, false
    assert_equal 4, daily_deal.bar_codes.count
    assert_equal %w{ 01234 56789 abcde fghij }, daily_deal.bar_codes.map(&:code)
    assert_equal [false] * 4, daily_deal.bar_codes.map(&:assigned)
    
    daily_deal.import_bar_codes StringIO.new("klmno\npqrst\n"), true, false
    assert_equal 2, daily_deal.bar_codes.count
    assert_equal %w{ klmno pqrst }, daily_deal.bar_codes.map(&:code)
    assert_equal [false] * 2, daily_deal.bar_codes.map(&:assigned)
  end

  test "default bar code encoding format" do
    assert_equal Gbarcode::BARCODE_128B, DailyDeal.new.bar_code_encoding_format
  end

  test "assign bar code" do
    daily_deal = Factory(:daily_deal)
    codes = %w{ 01234 56789 abcde fghij }
    daily_deal.import_bar_codes StringIO.new(codes.join("\n") << "\n"), false, false

    assert_equal 4, daily_deal.bar_codes.count

    4.times do |i|
      bar_code = daily_deal.assign_bar_code
      assert_equal codes[i], bar_code
    end

    assert_raise RuntimeError do
      daily_deal.assign_bar_code
    end
    assert_equal 4, daily_deal.bar_codes.count
  end

  context "bar code ordering" do
    setup do
      @daily_deal = Factory(:daily_deal)
      @bar_code1  = Factory(:bar_code, :bar_codeable => @daily_deal)
      @bar_code2  = Factory(:bar_code, :bar_codeable => @daily_deal, :position => "3")
      @bar_code3  = Factory(:bar_code, :bar_codeable => @daily_deal, :position => "2")
    end

    should "order by bar_code position by default" do
      assert_equal [@bar_code1, @bar_code3, @bar_code2], @daily_deal.reload.bar_codes
    end
  end
  
  context "barcodes, deal quantity, and certificates_to_generate_per_unit_quantity" do
    
    context "when 5 barcodes are uploaded, and certificates_to_generate_per_unit_quantity is 1" do
      
      setup do
        @deal = Factory :daily_deal, :quantity => 20, :certificates_to_generate_per_unit_quantity => 1
        @deal.bar_codes_csv = StringIO.new(20.times.map { |i| "barcode#{i}" }.join("\n"))
      end
      
      context "when the quantity is set to 10" do
        
        setup do
          @deal.quantity = 10
        end
        
        should "reset the quantity to 20 on validation and create the barcodes" do
          assert_difference("BarCode.count", 20) { assert @deal.valid? }
          assert_equal 20, @deal.quantity
        end
        
      end
      
      context "when the certificates_to_generate_per_unit_quantity is 3" do
        
        setup do
          @deal.certificates_to_generate_per_unit_quantity = 3
        end
        
        should "be invalid, because certificates_to_generate_per_unit_quantity does not divide evenly " +
               "into the number of uploaded barcodes" do
          assert_no_difference("BarCode.count") { assert @deal.invalid? }
          assert_equal ["certificates_to_generate_per_unit_quantity (3) must divide evenly into the number of barcodes (20), but does not"],
                       @deal.errors.full_messages
        end
        
      end
      
      context "when the certificates_to_generate_per_unit_quantity is 2" do
        
        setup do
          @deal.certificates_to_generate_per_unit_quantity = 2
        end
        
        should "set the deal quantity to 10 on validation, and create the barcodes" do
          assert_equal 20, @deal.quantity
          assert_difference("BarCode.count", 20) { assert @deal.valid? }
          assert_equal 10, @deal.quantity
        end
        
      end
      
    end
    
  end
  
  context "barcode assignment to captured purchases with certificates_to_generate_per_unit_quantity > 1" do
    
    setup do
      @deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 2
      puts @deal.quantity
      @deal.bar_codes_csv = StringIO.new(20.times.map { |i| "barcode#{i}" }.join("\n"))
      @deal.save!
      @purchase = Factory :captured_daily_deal_purchase, :daily_deal => @deal, :quantity => 3
      @certificates = @purchase.daily_deal_certificates
    end
    
    should "assign a barcode to each of the generated vouchers" do
      assert_equal 6, @certificates.size
      assert @certificates.all? { |c| c.bar_code.present? }
    end
    
  end

end

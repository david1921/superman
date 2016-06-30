require File.dirname(__FILE__) + "/../helpers_helper"

class DailyDealVariationsHelperTest < Test::Unit::TestCase

  def setup
    @helper = Object.new.extend(DailyDealVariationsHelper)
  end

  context "#travelsavers_product_code_is_editable?" do
    
    setup do
      @variation = mock('variation')
      @deal = mock('daily deal')
    end
    
    should "return false when the daily deal is syndicated or the variation travelsavers_product_code is not editable" do
      @deal.stubs(:syndicated?).returns(true)
      @variation.stubs(:travelsavers_product_code_is_editable?).returns(false)      
      assert !@helper.travelsavers_product_code_is_editable?(@deal, @variation)
      
      @deal.stubs(:syndicated?).returns(true)
      @variation.stubs(:travelsavers_product_code_is_editable?).returns(true)      
      assert !@helper.travelsavers_product_code_is_editable?(@deal, @variation)      
      
      @deal.stubs(:syndicated?).returns(false)  
      @variation.stubs(:travelsavers_product_code_is_editable?).returns(false)             
      assert !@helper.travelsavers_product_code_is_editable?(@deal, @variation)      
    end
    
    should "return true when the daily deal is not syndicated and the variation travelsavers_product_code is editable" do
      @deal.stubs(:syndicated?).returns(false)      
      @variation.stubs(:travelsavers_product_code_is_editable?).returns(true)      
      assert @helper.travelsavers_product_code_is_editable?(@deal, @variation)
    end    
  end

  context "#daily_deal_variations_index_hash?" do
    setup do
      @variation1 = stub(:value_proposition => 'test value prop',
                         :value => 100.50,
                         :price => 50.0,
                         :min_quantity => 1,
                         :max_quantity => 2,
                         :number_sold => 10,
                         :quantity => 10,
                         :terms => 'some test terms',
                         :id => 1234)
      @publisher = stub(:production_daily_deal_host => 'http://pork-beef.com')
      @deal = stub(:daily_deal_variations => [@variation1], :publisher => @publisher)
      @deal.stubs(:pay_using?).with(:travelsavers).returns(false)
    end


    should "map all the variations to the correct hash" do
      assert_equal([{:price=>50.0,
                     :terms=>"some test terms",
                     :minimum_purchase_quantity=>1,
                     :maximum_purchase_quantity=>2,
                     :value=>100.5,
                     :total_quantity_available=>10,
                     :quantity_sold=>10,
                     :daily_deal_variation_id=>@variation1.id,
                     :value_proposition=>"test value prop"},
                    ], @helper.daily_deal_variations_index_hash(@deal))
    end

  end
end

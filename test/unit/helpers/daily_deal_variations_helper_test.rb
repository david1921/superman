require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealVariationsHelperTest < ActionView::TestCase

  context "#daily_deal_variations_index_hash?" do
    setup do
      @deal = Factory(:daily_deal)
      @deal.publisher.update_attributes! :enable_daily_deal_variations => true, :production_daily_deal_host => 'http://pork-beef.com'
      @variation1 = Factory(:daily_deal_variation, :terms => "some test terms", :daily_deal => @deal, :value => 100.50, :price => 50.0, :min_quantity => 1, :max_quantity => 2,:quantity => 10)
    end


    should "map all the variations to the correct hash" do
      assert_equal([{:price=>50.0,
                     :terms=>"<p>some test terms</p>",
                     :minimum_purchase_quantity=>1,
                     :maximum_purchase_quantity=>2,
                     :value=>100.5,
                     :total_quantity_available=>10,
                     :quantity_sold=>0,
                     :daily_deal_variation_id=>@variation1.id,
                     :value_proposition=>"$100.50 for only $50.00!"},
                   ], daily_deal_variations_index_hash(@deal))
    end

    should 'include a payment_url if the publisher uses the travelsavers payment method' do
      @deal.expects(:pay_using?).with(:travelsavers).returns(true)
      assert_equal([{:price=>50.0,
                     :terms=>"<p>some test terms</p>",
                     :minimum_purchase_quantity=>1,
                     :maximum_purchase_quantity=>2,
                     :value=>100.5,
                     :total_quantity_available=>10,
                     :quantity_sold=>0,
                     :daily_deal_variation_id=>@variation1.id,
                     :value_proposition=>"$100.50 for only $50.00!",
                     :methods=>
                         {:purchase_url=>
                              "http://http://pork-beef.com/daily_deals/#{@deal.to_param}/daily_deal_purchases/new?daily_deal_variation_id=#{@variation1.id}"}
                    }
                   ], daily_deal_variations_index_hash(@deal))
    end

  end

end

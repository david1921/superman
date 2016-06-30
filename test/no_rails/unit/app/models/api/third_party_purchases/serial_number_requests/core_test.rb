require File.dirname(__FILE__) + "/../../../../models_helper"

# hydra class Api::ThirdPartyPurchases::SerialNumberRequests::CoreTest

module Api::ThirdPartyPurchases::SerialNumberRequests
  class CoreTest < Test::Unit::TestCase
    def setup
      @request = Object.new.extend(Core)
    end

    context "#execute" do
      should "create and capture purchase when valid" do
        purchase = mock('purchase')
        @request.stubs(:valid?).returns(true)
        @request.stubs(:create_and_capture_purchase).returns(purchase)
        assert_equal purchase, @request.execute
      end
    end

    context "#success?" do
      should "return true if purchase persisted" do
        @request.stubs(:purchase_persisted?).returns(true)
        assert @request.success?
      end
    end

    context "#vouchers" do
      should "return the purchase's daily deal certificates" do
        certs = mock('deal certificates')
        purchase = mock('purchase', :daily_deal_certificates => certs)
        @request.stubs(:purchase).returns(purchase)
        assert_equal certs, @request.vouchers
      end

      should "return [] when no purchase" do
        @request.stubs(:purchase).returns(nil)
        assert_equal [], @request.vouchers
      end
    end

    context "#deal_qty_remaining" do
      should "return the deal's remaining quantity" do
        deal = mock('daily deal', :number_left => 10)
        @request.stubs('daily_deal').returns(deal)
        assert_equal 10, @request.deal_qty_remaining
      end

      should "not return less than zero" do
        deal = mock('daily deal', :number_left => -1)
        @request.stubs('daily_deal').returns(deal)
        assert_equal 0, @request.deal_qty_remaining
      end

      should "return nil when deal quantity is unlimited" do
        deal = mock('daily deal', :number_left => nil)
        @request.stubs('daily_deal').returns(deal)
        assert_nil @request.deal_qty_remaining
      end
    end

    context "#deal_sold_out?" do
      should "return true when the remaining deal quantity <= 0" do
        @request.stubs('deal_qty_remaining').returns(-1)
        assert @request.deal_sold_out?
        @request.stubs('deal_qty_remaining').returns(0)
        assert @request.deal_sold_out?
      end

      should "return false is remaining deal qty is > 0" do
        @request.stubs('deal_qty_remaining').returns(1)
        assert !@request.deal_sold_out?
      end

      should "return nil when remaining deal qty is nil" do
        @request.stubs('deal_qty_remaining').returns(nil)
        assert_nil @request.deal_sold_out?
      end
    end

    context "#requested_qty" do
      should "return number of voucher requests in xml" do
        num_voucher_requests = mock
        @request.stubs(:num_xml_voucher_requests).returns(num_voucher_requests)
        assert_equal num_voucher_requests, @request.requested_qty
      end
    end
    
    context "private methods" do
      context "#attributes_from_xml" do
        setup do
          @store = stub('store', :id => 10)
          @deal = stub('daily_deal', :id => 20)
          @request.stubs(:daily_deal).returns(nil)
          @request.stubs(:xml_data).returns(HashWithIndifferentAccess.new({:voucher_requests => {:voucher_request => {:sequence => 10}}}))
          @request.instance_variable_set(:@store, @store)
        end

        should "return nil for daily_deal_id when deal is nil" do
          assert_nil @request.send(:attributes_from_xml)[:daily_deal_id]
        end

        should "return nil for store_id when store is nil" do
          @request.instance_variable_set(:@store, nil)
          assert_nil @request.send(:attributes_from_xml)[:store_id]
        end
      end

      context "#voucher_requests_from_xml_data(data)" do
        should "return an array of hashes when one voucher request" do
          expected = [{"sequence"=>"10", "redeemer_name"=>"Joe Da Butcher"}]
          assert_equal expected, @request.send(:voucher_requests_from_xml_data, Hash.from_xml(<<EOF)['daily_deal_purchase'])
<daily_deal_purchase>
  <voucher_requests>
    <voucher_request sequence="10">
      <redeemer_name>Joe Da Butcher</redeemer_name>
    </voucher_request>
  </voucher_requests>
</daily_deal_purchase>
EOF
        end

        should "return an array of hashes when two voucher requests" do
          expected = [{"sequence"=>"10", "redeemer_name"=>"Joe Da Butcher"}, {"sequence"=>"20", "redeemer_name"=>"Oh Takashawa"}]
          assert_equal expected, @request.send(:voucher_requests_from_xml_data, Hash.from_xml(<<EOF)['daily_deal_purchase'])
<daily_deal_purchase>
  <voucher_requests>
    <voucher_request sequence="10">
      <redeemer_name>Joe Da Butcher</redeemer_name>
    </voucher_request>
    <voucher_request sequence="20">
      <redeemer_name>Oh Takashawa</redeemer_name>
    </voucher_request>
  </voucher_requests>
</daily_deal_purchase>
EOF
        end
      end

      context "#sort_voucher_requests_by_sequence(voucher_requests)" do
        should "sort the array by sequence and collect the redeemer name" do
          voucher_requests = [{'sequence' => '30', 'redeemer_name' => 'thirty'}, {'sequence' => '20', 'redeemer_name' => 'twenty'}]
          assert_equal ['twenty', 'thirty'], @request.send(:sort_voucher_requests_by_sequence, voucher_requests)
        end
      end
      
    end
  end
end
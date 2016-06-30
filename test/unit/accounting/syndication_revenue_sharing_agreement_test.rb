require File.dirname(__FILE__) + "/../../test_helper"

class SyndicationRevenueSharingAgreementTest < ActiveSupport::TestCase
  
  context "validation" do
    setup do
      @revenue_sharing_agreement = Factory.build(:syndication_revenue_sharing_agreement)
    end
    
    should "require effective date" do
      @revenue_sharing_agreement.effective_date = nil
      @revenue_sharing_agreement.valid?
      assert_equal "Effective date can't be blank", @revenue_sharing_agreement.errors.on(:effective_date)
    end
    
    context "of syndication fees" do
      setup do
         @revenue_sharing_agreement.effective_date = Time.zone.now
      end
      
      should "validate syndication fee gross values" do
        #see test/no_rails/unit/app/models/accounting/revenue_sharing_agreement_validation_test.rb
        @revenue_sharing_agreement.syndication_fee_gross_percentage = -1
        @revenue_sharing_agreement.valid?
        assert_equal "Syndication fee gross percentage must be a number between 0 and 100.", @revenue_sharing_agreement.errors.on(:syndication_fee_gross_percentage)
      end
      
    end
    
    context "of syndication credit card fees" do
      should "NOT allow invalid syndication credit card fee sources" do
        ['foo', nil].each do |value|
          @revenue_sharing_agreement.credit_card_fee_source = value
          @revenue_sharing_agreement.valid?
          assert_equal "Credit card fee source must be Actual Fees, Estimated, Fixed Fee ($/Transaction) or Fixed Fee (%).",
                       @revenue_sharing_agreement.errors.on(:credit_card_fee_source)
        end
      end
      
      should "allow valid syndication credit card fee sources" do
        ['actual_fees', 'estimated', 'fixed_amount', 'fixed_percentage'].each do |value|
          @revenue_sharing_agreement.credit_card_fee_source = value
          @revenue_sharing_agreement.valid?
          assert_nil @revenue_sharing_agreement.errors.on(:credit_card_fee_source), 
                     "Expected #{value} to be a valid syndication_credit_card_fee_source"
        end
      end
      
      should "validate syndication credit card fees" do
        #see test/no_rails/unit/app/models/accounting/revenue_sharing_agreement_validation_test.rb
        @revenue_sharing_agreement.credit_card_fee_source = 'fixed_percentage'
        @revenue_sharing_agreement.credit_card_fee_fixed_percentage = 101
        @revenue_sharing_agreement.valid?
        assert_equal "Credit card fee fixed percentage must be a number between 0 and 100.", @revenue_sharing_agreement.errors.on(:credit_card_fee_fixed_percentage)
      end
    end
    
  end
  
  
  context "finders" do
    context "current" do
      setup do
        @most_recent_rsa = Factory(:syndication_revenue_sharing_agreement, :effective_date => 2.days.ago)
        @less_recent_rsa = Factory(:syndication_revenue_sharing_agreement, :effective_date => 3.days.ago)
      end
      
      should "return agreement with most recent effective date" do
        revenue_sharing_agreement = Accounting::SyndicationRevenueSharingAgreement.current
        assert revenue_sharing_agreement.is_a?(Accounting::SyndicationRevenueSharingAgreement), "Should return one SyndicationRevenueSharingAgreement"
        assert_equal @most_recent_rsa.syndication_flat_fee, revenue_sharing_agreement.syndication_flat_fee
        assert_equal @most_recent_rsa, revenue_sharing_agreement, "Should return agreement with most recent effective date"
      end
    end
  end
  
  
  context "credit card fee details" do
    setup do
      @agreement = Accounting::SyndicationRevenueSharingAgreement.new
    end
    
    context "credit_card_fee_split_description" do
      context "actual_fees" do
        should "provide actual fees description" do
          @agreement.expects(:credit_card_fee_source).returns('actual_fees')
          @agreement.expects(:credit_card_fees_gross_percentages_detail).returns("foo")
          @agreement.expects(:credit_card_fees_net_percentages_detail).returns("bar")
          actual_details = @agreement.credit_card_fee_split_details
          assert_equal "foo bar", actual_details
        end
      end
      context "estimated" do
        should "provide actual fees description" do
          @agreement.expects(:credit_card_fee_source).returns('estimated')
          @agreement.expects(:credit_card_fees_gross_percentages_detail).returns("foo")
          @agreement.expects(:credit_card_fees_net_percentages_detail).returns("bar")
          actual_details = @agreement.credit_card_fee_split_details
          assert_equal "foo bar", actual_details
        end
      end
      context "fixed_amount" do
        should "provide fixed fee amount description" do
          @agreement.expects(:credit_card_fee_source).returns('fixed_amount')
          @agreement.expects(:credit_card_fee_fixed_amount).returns(3)
          actual_details = @agreement.credit_card_fee_split_details
          assert_equal "$3", actual_details
        end
      end
      context "fixed_percentage" do
        should "provide fixed fee percentage description" do
          @agreement.expects(:credit_card_fee_source).returns('fixed_percentage')
          @agreement.expects(:credit_card_fee_fixed_percentage).returns(1)
          actual_details = @agreement.credit_card_fee_split_details
          assert_equal "1%", actual_details
        end
      end
    end
    
    context "credit_card_fees_gross_percentages_detail" do
      should "provide details" do
        @agreement.expects(:credit_card_fee_gross_pro_rata?).returns(false)
        @agreement.expects(:credit_card_fee_gross_source_percentage).returns(20).at_least_once
        @agreement.expects(:credit_card_fee_gross_merchant_percentage).returns(49).at_least_once
        @agreement.expects(:credit_card_fee_gross_distributor_percentage).returns(26).at_least_once
        @agreement.expects(:credit_card_fee_gross_aa_percentage).returns(5).at_least_once
        expected_details = "[Gross: Source 20% Merchant 49% Distributor 26% AA 5%]" 
        expected_details << "" 
        actual_details = @agreement.send(:credit_card_fees_gross_percentages_detail)
        assert_equal expected_details, actual_details
      end
      
      should "provide pro rata details" do
        @agreement.expects(:credit_card_fee_gross_pro_rata?).returns(true)
        expected_details = "[Gross: Pro Rata]"
        actual_details = @agreement.send(:credit_card_fees_gross_percentages_detail)
        assert_equal expected_details, actual_details
      end
    end
    
    context "credit_card_fees_net_percentages_detail" do
      should "provide details" do
        @agreement.expects(:credit_card_fee_net_pro_rata?).returns(false)
        @agreement.expects(:credit_card_fee_net_source_percentage).returns(20).at_least_once
        @agreement.expects(:credit_card_fee_net_merchant_percentage).returns(49).at_least_once
        @agreement.expects(:credit_card_fee_net_distributor_percentage).returns(26).at_least_once
        @agreement.expects(:credit_card_fee_net_aa_percentage).returns(5).at_least_once
        expected_details = "[Net: Source 20% Merchant 49% Distributor 26% AA 5%]"
        actual_details = @agreement.send(:credit_card_fees_net_percentages_detail)
        assert_equal expected_details, actual_details
      end
      
      should "provide pro rata details" do
        @agreement.expects(:credit_card_fee_net_pro_rata?).returns(true)
        expected_details = "[Net: Pro Rata]"
        actual_details = @agreement.send(:credit_card_fees_net_percentages_detail)
        assert_equal expected_details, actual_details
      end
    end
    
  end
  
end

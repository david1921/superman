require File.dirname(__FILE__) + "/../../test_helper"

class PlatformRevenueSharingAgreementTest < ActiveSupport::TestCase
  
  context "validation" do
    setup do
      @agreement = Factory.build(:platform_revenue_sharing_agreement)
    end
    
    should "require effective date" do
      @agreement.effective_date = nil
      @agreement.valid?
      assert_equal "Effective date can't be blank", @agreement.errors.on(:effective_date)
    end
    
    context "of platform fees" do
      setup do
         @agreement.effective_date = Time.zone.now
      end
      
      should "validate platform fee gross values" do
        #see test/no_rails/unit/app/models/accounting/revenue_sharing_agreement_validation_test.rb
        @agreement.platform_fee_gross_percentage = -1
        @agreement.valid?
        assert_equal "Platform fee gross percentage must be a number between 0 and 100.", @agreement.errors.on(:platform_fee_gross_percentage)
      end
      
    end
    
    context "of platform credit card fees" do
      should "NOT allow invalid platform credit card fee sources" do
        ['foo', nil].each do |value|
          @agreement.credit_card_fee_source = value
          @agreement.valid?
          assert_equal "Credit card fee source must be Actual Fees, Estimated, Fixed Fee ($/Transaction) or Fixed Fee (%).",
                       @agreement.errors.on(:credit_card_fee_source)
        end
      end
      
      should "allow valid platform credit card fee sources" do
        ['actual_fees', 'estimated', 'fixed_amount', 'fixed_percentage'].each do |value|
          @agreement.credit_card_fee_source = value
          @agreement.valid?
          assert_nil @agreement.errors.on(:credit_card_fee_source), 
                     "Expected #{value} to be a valid platform_credit_card_fee_source"
        end
      end
      
      should "validate platform credit card fees" do
        #see test/no_rails/unit/app/models/accounting/revenue_sharing_agreement_validation_test.rb
        @agreement.credit_card_fee_source = 'fixed_percentage'
        @agreement.credit_card_fee_fixed_percentage = 101
        @agreement.valid?
        assert_equal "Credit card fee fixed percentage must be a number between 0 and 100.", @agreement.errors.on(:credit_card_fee_fixed_percentage)
      end
    end
    
  end
  
  context "finders" do
    context "current" do
      setup do
        @most_recent_rsa = Factory(:platform_revenue_sharing_agreement, :effective_date => 2.days.ago)
        @less_recent_rsa = Factory(:platform_revenue_sharing_agreement, :effective_date => 3.days.ago)
      end
      
      should "return agreement with most recent effective date" do
        revenue_sharing_agreement = Accounting::PlatformRevenueSharingAgreement.current
        assert revenue_sharing_agreement.is_a?(Accounting::PlatformRevenueSharingAgreement), "Should return one PlatformRevenueSharingAgreement"
        assert_equal @most_recent_rsa.platform_flat_fee, revenue_sharing_agreement.platform_flat_fee
        assert_equal @most_recent_rsa, revenue_sharing_agreement, "Should return agreement with most recent effective date"
      end
    end
  end
  
  context "credit card fee details" do
    setup do
      @agreement = Accounting::PlatformRevenueSharingAgreement.new
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
        @agreement.expects(:credit_card_fee_gross_publisher_percentage).returns(1).at_least_once
        @agreement.expects(:credit_card_fee_gross_merchant_percentage).returns(2).at_least_once
        @agreement.expects(:credit_card_fee_gross_aa_percentage).returns(3).at_least_once
        expected_details = "Gross [Publisher 1% Merchant 2% AA 3%]"
        actual_details = @agreement.send(:credit_card_fees_gross_percentages_detail)
        assert_equal expected_details, actual_details
      end
      
      should "provide pro rata details" do
        @agreement.expects(:credit_card_fee_gross_pro_rata?).returns(true)
        expected_details = "Gross [Pro Rata]"
        actual_details = @agreement.send(:credit_card_fees_gross_percentages_detail)
        assert_equal expected_details, actual_details
      end
    end
    
    context "credit_card_fees_net_percentages_detail" do
      should "provide details" do
        @agreement.expects(:credit_card_fee_net_pro_rata?).returns(false)
        @agreement.expects(:credit_card_fee_net_publisher_percentage).returns(1).at_least_once
        @agreement.expects(:credit_card_fee_net_merchant_percentage).returns(2).at_least_once
        @agreement.expects(:credit_card_fee_net_aa_percentage).returns(3).at_least_once
        expected_details = "Net [Publisher 1% Merchant 2% AA 3%]"
        actual_details = @agreement.send(:credit_card_fees_net_percentages_detail)
        assert_equal expected_details, actual_details
      end
      
      should "provide pro rata details" do
        @agreement.expects(:credit_card_fee_net_pro_rata?).returns(true)
        expected_details = "Net [Pro Rata]"
        actual_details = @agreement.send(:credit_card_fees_net_percentages_detail)
        assert_equal expected_details, actual_details
      end
    end
    
  end
  
end

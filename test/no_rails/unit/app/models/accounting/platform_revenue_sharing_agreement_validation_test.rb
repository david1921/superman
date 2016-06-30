require File.dirname(__FILE__) + "/../../models_helper"

class PlatformRevenueSharingAgreementValidationTest < Test::Unit::TestCase
  
  class MockRevenueSharingAgreement
    include Accounting::PlatformRevenueSharingAgreementValidation
  end
  
  def setup
    @revenue_sharing_agreement = MockRevenueSharingAgreement.new
  end
  
  context "validate_platform_fee_values" do
    
    should "allow blank platform fee when agreement type is publishing group" do
      @revenue_sharing_agreement.expects(:validate_platform_fee_percentages)
      @revenue_sharing_agreement.expects(:agreement_type).returns('PublishingGroup')
      @revenue_sharing_agreement.expects(:validate_blank).with(:platform_flat_fee, Accounting::RevenueSharingAgreementConstants::PLATFORM_FEE_FLAT_FEE_MESSAGE)
      @revenue_sharing_agreement.validate_platform_fee_values
    end
    
    should "validate platform fee when agreement type is publisher" do
      @revenue_sharing_agreement.expects(:validate_platform_fee_percentages)
      @revenue_sharing_agreement.expects(:agreement_type).returns('PublishingGroup')
      @revenue_sharing_agreement.expects(:validate_blank).with(:platform_flat_fee, Accounting::RevenueSharingAgreementConstants::PLATFORM_FEE_FLAT_FEE_MESSAGE)
      @revenue_sharing_agreement.validate_platform_fee_values
    end
    
    should "validate platform fee when agreement type is deal" do
      @revenue_sharing_agreement.expects(:validate_platform_fee_percentages)
      @revenue_sharing_agreement.expects(:agreement_type).returns('Deal')
      @revenue_sharing_agreement.expects(:validate_amount).with(:platform_flat_fee)
      @revenue_sharing_agreement.validate_platform_fee_values
    end
    
  end
  
  context "validate_credit_card_fees" do
    
    setup do
      @errors = mock("errors")
      @revenue_sharing_agreement.stubs(:errors).returns(@errors)
    end
    
    should "validate values when actual_fees" do
      @revenue_sharing_agreement.expects(:credit_card_fee_source).returns('actual_fees')
      @revenue_sharing_agreement.expects(:validate_fixed_credit_card_fee_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_MESSAGE)
      @revenue_sharing_agreement.expects(:validate_credit_card_fee_gross_values)
      @revenue_sharing_agreement.expects(:validate_credit_card_fee_net_values)
      @revenue_sharing_agreement.validate_credit_card_fees
    end
    
    should "validate values when estimated" do
      @revenue_sharing_agreement.expects(:credit_card_fee_source).returns('estimated')
      @revenue_sharing_agreement.expects(:validate_fixed_credit_card_fee_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_ESTIMATED_MESSAGE)
      @revenue_sharing_agreement.expects(:validate_credit_card_fee_gross_values)
      @revenue_sharing_agreement.expects(:validate_credit_card_fee_net_values)
      @revenue_sharing_agreement.validate_credit_card_fees
    end
    
    should "validate values when fixed_amount" do
      @revenue_sharing_agreement.expects(:credit_card_fee_source).returns('fixed_amount')
      @revenue_sharing_agreement.expects(:validate_credit_card_fee_gross_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_AMOUNT_MESSAGE)
      @revenue_sharing_agreement.expects(:validate_credit_card_fee_net_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_AMOUNT_MESSAGE)
      @revenue_sharing_agreement.expects(:validate_blank).with(:credit_card_fee_fixed_percentage, Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_AMOUNT_MESSAGE)
      @revenue_sharing_agreement.expects(:validate_amount).with(:credit_card_fee_fixed_amount)
      @revenue_sharing_agreement.validate_credit_card_fees
    end
    
    should "validate values when fixed_percentage" do
      @revenue_sharing_agreement.expects(:credit_card_fee_source).returns('fixed_percentage')
      @revenue_sharing_agreement.expects(:validate_credit_card_fee_gross_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_PERCENTAGE_MESSAGE)
      @revenue_sharing_agreement.expects(:validate_credit_card_fee_net_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_PERCENTAGE_MESSAGE)
      @revenue_sharing_agreement.expects(:validate_blank).with(:credit_card_fee_fixed_amount, Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FIXED_PERCENTAGE_MESSAGE)
      @revenue_sharing_agreement.expects(:validate_percentage).with(:credit_card_fee_fixed_percentage)
      @revenue_sharing_agreement.validate_credit_card_fees
    end
  end

  context "private validation methods" do
    context "validate_credit_card_fee_gross_values_not_present" do
      setup do
        @errors = mock("errors")
        @revenue_sharing_agreement.stubs(:errors).returns(@errors)
      end

      should "validate all associated values" do
        expect_not_false(:credit_card_fee_gross_pro_rata, true, "foo")
        expect_present(:credit_card_fee_gross_publisher_percentage, 1, "foo")
        expect_present(:credit_card_fee_gross_merchant_percentage, 2, "foo")
        expect_present(:credit_card_fee_gross_aa_percentage, 3, "foo")
        @revenue_sharing_agreement.send(:validate_credit_card_fee_gross_values_not_present, "foo")
      end
      
      should "validate all associated values except pro rata" do
        expect_present(:credit_card_fee_gross_publisher_percentage, 1, "foo")
        expect_present(:credit_card_fee_gross_merchant_percentage, 2, "foo")
        expect_present(:credit_card_fee_gross_aa_percentage, 3, "foo")
        @revenue_sharing_agreement.send(:validate_credit_card_fee_gross_values_not_present, "foo", false)
      end
    end
    
    context "validate_credit_card_fee_net_values_not_present" do
      setup do
        @errors = mock("errors")
        @revenue_sharing_agreement.stubs(:errors).returns(@errors)
      end
      
      should "validate all associated values" do
        expect_not_false(:credit_card_fee_net_pro_rata, true, "foo")
        expect_present(:credit_card_fee_net_publisher_percentage, 1, "foo")
        expect_present(:credit_card_fee_net_merchant_percentage, 2, "foo")
        expect_present(:credit_card_fee_net_aa_percentage, 3, "foo")
        @revenue_sharing_agreement.send(:validate_credit_card_fee_net_values_not_present, "foo")
      end
      
      should "validate all associated values except pro rata" do
        expect_present(:credit_card_fee_gross_publisher_percentage, 1, "foo")
        expect_present(:credit_card_fee_gross_merchant_percentage, 2, "foo")
        expect_present(:credit_card_fee_gross_aa_percentage, 3, "foo")
        @revenue_sharing_agreement.send(:validate_credit_card_fee_gross_values_not_present, "foo", false)
      end
    end
    
    context "validate_fixed_credit_card_fee_values_not_present" do
      setup do
        @errors = mock("errors")
        @revenue_sharing_agreement.stubs(:errors).returns(@errors)
      end
    
      should "validate all associated values" do
        expect_present(:credit_card_fee_fixed_amount, 1, "foo")
        expect_present(:credit_card_fee_fixed_percentage, 2, "foo")
        @revenue_sharing_agreement.send(:validate_fixed_credit_card_fee_values_not_present, "foo")
      end
    end
    
    context "validate_credit_card_fee_gross_values" do
      setup do
        @errors = mock("errors")
        @revenue_sharing_agreement.stubs(:errors).returns(@errors)
      end
    
      should "ensure no values if pro rata" do
        @revenue_sharing_agreement.expects(:credit_card_fee_gross_pro_rata).returns(true)
        @revenue_sharing_agreement.expects(:validate_credit_card_fee_gross_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PRO_RATA_MESSAGE, false)
        @revenue_sharing_agreement.send(:validate_credit_card_fee_gross_values)
      end
    
      should "ensure values add up to 100% when not pro rata" do
        @revenue_sharing_agreement.expects(:credit_card_fee_gross_pro_rata).returns(false)
        @revenue_sharing_agreement.expects(:validate_credit_card_fee_gross_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PRO_RATA_MESSAGE, false).never
        @revenue_sharing_agreement.expects(:validate_sum).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_GROSS_ATTRIBUTES, 
                                                               100,
                                                               Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_GROSS_SUM_MESSAGE)
        @revenue_sharing_agreement.send(:validate_credit_card_fee_gross_values)
      end
    end
    
    context "validate_credit_card_fee_net_values" do
      setup do
        @errors = mock("errors")
        @revenue_sharing_agreement.stubs(:errors).returns(@errors)
      end

      should "ensure no values if pro rata" do
        @revenue_sharing_agreement.expects(:credit_card_fee_net_pro_rata).returns(true)
        @revenue_sharing_agreement.expects(:validate_credit_card_fee_net_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PRO_RATA_MESSAGE, false)
        @revenue_sharing_agreement.send(:validate_credit_card_fee_net_values)
      end
    
      should "ensure values add up to 100% when not pro rata" do
        @revenue_sharing_agreement.expects(:credit_card_fee_net_pro_rata).returns(false)
        @revenue_sharing_agreement.expects(:validate_credit_card_fee_net_values_not_present).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PRO_RATA_MESSAGE, false).never
        @revenue_sharing_agreement.expects(:validate_sum).with(Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_NET_ATTRIBUTES, 
                                                               100,
                                                               Accounting::RevenueSharingAgreementConstants::CREDIT_CARD_FEE_SOURCE_FEES_PLATFORM_NET_SUM_MESSAGE)
        @revenue_sharing_agreement.send(:validate_credit_card_fee_net_values)
      end
    end
    
    context "validate_platform_fee_percentages" do
      setup do
        @errors = mock("errors")
        @revenue_sharing_agreement.stubs(:errors).returns(@errors)
      end
      
      should "ensure not gross and net" do
        @revenue_sharing_agreement.expects(:value_of).with(:platform_fee_gross_percentage).returns(1)
        @revenue_sharing_agreement.expects(:value_of).with(:platform_fee_net_percentage).returns(2)
        @errors.expects(:add).with(:base, Accounting::RevenueSharingAgreementConstants::PLATFORM_FEE_MUTUALLY_EXCLUSIVE_MESSAGE)
        @revenue_sharing_agreement.send(:validate_platform_fee_percentages)
      end
      
      should "ensure gross and net not blank" do
        @revenue_sharing_agreement.expects(:value_of).with(:platform_fee_gross_percentage).returns("")
        @revenue_sharing_agreement.expects(:value_of).with(:platform_fee_net_percentage).returns(nil)
        @errors.expects(:add).with(:base, Accounting::RevenueSharingAgreementConstants::PLATFORM_FEE_MISSING_MESSAGE)
        @revenue_sharing_agreement.send(:validate_platform_fee_percentages)
      end
      
      should "validate gross" do
        @revenue_sharing_agreement.expects(:value_of).with(:platform_fee_gross_percentage).returns(1).at_least_once
        @revenue_sharing_agreement.expects(:value_of).with(:platform_fee_net_percentage).returns(nil)
        @errors.expects(:add).never
        @revenue_sharing_agreement.send(:validate_platform_fee_percentages)
      end
      
      should "validate net" do
        @revenue_sharing_agreement.expects(:value_of).with(:platform_fee_net_percentage).returns(1).at_least_once
        @revenue_sharing_agreement.expects(:value_of).with(:platform_fee_gross_percentage).returns(nil)
        @errors.expects(:add).never
        @revenue_sharing_agreement.send(:validate_platform_fee_percentages)
      end
    end
      
  end
  
  private
    
  def expect_present(attribute, value, message)
    @revenue_sharing_agreement.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).with(attribute, message)
  end
  
  def expect_blank(attribute, value)
    @revenue_sharing_agreement.expects(:value_of).with(attribute).returns(nil)
    @errors.expects(:add).never
  end
  
  def expect_not_false(attribute, value, message)
    @revenue_sharing_agreement.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).with(attribute, message)
  end
  
  def expect_false(attribute, value)
    @revenue_sharing_agreement.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).never
  end
  
end
require File.dirname(__FILE__) + "/../../models_helper"

class OffPlatformDailyDealPurchases::ValidationsTest < Test::Unit::TestCase
  def setup
    @purchase = stub('Purchase').extend(OffPlatformDailyDealPurchases::Validations)
  end

  context "#recipients_match_quantity" do
    setup do
      errors = stub(:add_to_base => nil)
      @purchase.stubs(:quantity => 3, :errors => errors)
      @error = "There should be #{@purchase.quantity} recipient names"
    end

    should "require some recipients" do
      @purchase.stubs(:recipient_names => nil)
      @purchase.errors.expects(:add_to_base).with(@error)
      @purchase.recipient_names_match_quantity
    end

    should "require number of recipient to match the purchase quantity" do
      @purchase.stubs(:recipient_names => stub(:size => @purchase.quantity - 1))
      @purchase.errors.expects(:add_to_base).with(@error)
      @purchase.recipient_names_match_quantity
    end

    should "require non-blank recipient names" do
      @purchase.stubs(:recipient_names => ['', 'John', 'Scott'])
      @purchase.errors.expects(:add_to_base).with(@error)
      @purchase.recipient_names_match_quantity
    end

    should "not set an error if recipients match quantity" do
      @purchase.stubs(:recipient_names => Array.new(@purchase.quantity, 'name'))
      @purchase.expects(:errors).never
      @purchase.recipient_names_match_quantity
    end

  end

  context "#consumer_is_nil" do
    setup do
      @purchase.stubs(:consumer)
      @purchase.stubs(:consumer_id)
      @errors = stub('errors')
      @purchase.stubs(:errors).returns(@errors)
    end

    should "require a nil consumer_id" do
      @purchase.stubs(:consumer_id).returns(stub('consumer_id'))
      @errors.expects(:add).with(:consumer_id, '%{attribute} must be nil')
      @purchase.consumer_is_nil
    end

    should "allow a nil consumer_id" do
      @purchase.stubs(:consumer_id).returns(nil)
      @purchase.expects(:errors).never
      @purchase.consumer_is_nil
    end
  end
end
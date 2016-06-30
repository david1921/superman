require File.dirname(__FILE__) + "/../test_helper"

class CreditTest < ActiveSupport::TestCase
  test "create" do
    consumer = Factory(:consumer)
    assert_difference 'Credit.count' do
      credit = Credit.create!(:consumer => consumer, :amount => "10.00", :memo => "Testing the credit")
      assert_equal consumer, credit.consumer
      assert_equal 10.00, credit.amount
    end
  end
  
  test "not valid with nil amount" do
    credit = Credit.new(:amount => nil)
    assert credit.invalid?, "Should not be valid with nil amount"
    assert_match /is not a number/, credit.errors.on(:amount)
  end

  test "not valid with non numeric amount" do
    credit = Credit.new(:amount => "xx.xx")
    assert credit.invalid?, "Should not be valid with non-numeric amount"
    assert_match /is not a number/, credit.errors.on(:amount)
  end

  test "not valid with negative amount" do
    credit = Credit.new(:amount => -10.00)
    assert credit.invalid?, "Should not be valid with negative amount"
    assert_match /must be greater than 0.0/, credit.errors.on(:amount)
  end
  
  test "not valid with zero amount" do
    credit = Credit.new(:amount => 0.00)
    assert credit.invalid?, "Should not be valid with zero amount"
    assert_match /must be greater than 0.0/, credit.errors.on(:amount)
  end
  
  test "reassigning amount raises an exception" do
    credit = Credit.create!(:consumer => Factory(:consumer), :amount => "10.00")
    assert_raise RuntimeError do
      credit.amount = 20.00
    end
  end
end

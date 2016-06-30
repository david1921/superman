require File.dirname(__FILE__) + "/../lib_helper"

class ModelValidationTest < Test::Unit::TestCase
  
  class MockModel
    include Analog::ModelValidation
  end
  
  def setup
    @model = MockModel.new
  end
  
  context "validate_percentage" do
    setup do
      @errors = mock("errors")
      @model.stubs(:errors).returns(@errors)
    end
    
    should "NOT accept a number less than zero " do
      expect_invalid_percentage(:foo, -1)
      @model.send(:validate_percentage, :foo)
    end
    
    should "NOT accept a number greater than 100" do
      expect_invalid_percentage(:foo, 101)
      @model.send(:validate_percentage, :foo)
    end
    
    should "NOT accept nil" do
      expect_invalid_percentage(:foo, nil)
      @model.send(:validate_percentage, :foo)
    end
    
    should "accept 0" do
      expect_valid_percentage(:foo, 0)
      @model.send(:validate_percentage, :foo)
    end
    
    should "accept 100" do
      expect_valid_percentage(:foo, 100)
      @model.send(:validate_percentage, :foo)
    end
    
    should "accept a number between 0 and 100" do
      expect_valid_percentage(:foo, 43)
      @model.send(:validate_percentage, :foo)
    end
    
  end
  
  context "validate_amount" do
    setup do
      @errors = mock("errors")
      @model.stubs(:errors).returns(@errors)
    end
    
    should "NOT accept nil" do
      expect_invalid_amount(:foo, nil)
      @model.send(:validate_amount, :foo)
    end
    
    should "NOT accept 0" do
      expect_invalid_amount(:foo, 0)
      @model.send(:validate_amount, :foo)
    end
    
    should "NOT accept a number less than zero" do
      expect_invalid_amount(:foo, -1)
      @model.send(:validate_amount, :foo)
    end
    
    should "accept a number greater than zero" do
      expect_valid_amount(:foo, 50)
      @model.send(:validate_amount, :foo)
    end
    
  end
  
  context "validate_blank" do
    setup do
      @errors = mock("errors")
      @model.stubs(:errors).returns(@errors)
    end
    
    should "NOT accept a number" do
      expect_present(:foo, 0, "foo")
      @model.send(:validate_blank, :foo, "foo")
    end
    
    should "NOT accept a letter" do
      expect_present(:foo, 'a', "foo")
      @model.send(:validate_blank, :foo, "foo")
    end
    
    should "accept a nil" do
      expect_blank(:foo, nil)
      @model.send(:validate_blank, :foo, "foo")
    end
    
    should "accept blank" do
      expect_blank(:foo, '')
      @model.send(:validate_blank, :foo, "foo")
    end
  end
  
  context "validate_false" do
    setup do
      @errors = mock("errors")
      @model.stubs(:errors).returns(@errors)
    end
    
    should "NOT accept true" do
      expect_not_false(:foo, true, "foo")
      @model.send(:validate_blank, :foo, "foo")
    end
    
    should "accept nil" do
      expect_false(:foo, nil)
      @model.send(:validate_blank, :foo, "foo")
    end
    
    should "accept false" do
      expect_false(:foo, false)
      @model.send(:validate_blank, :foo, "foo")
    end
    
  end
  
  context "validate_sum" do
    setup do
      @errors = mock("errors")
      @model.stubs(:errors).returns(@errors)
    end
    
    should "NOT accept attributes that do not sum to value" do
      expect_not_sum([:foo, :bar], 100, "doesnt add up")
      @model.send(:validate_sum, [:foo, :bar], 100, "doesnt add up")
    end
    
    should "accept attributes that sum to value" do
      expect_sum([:foo, :bar], 100)
      @model.send(:validate_sum, [:foo, :bar], 100, "doesnt add up")
    end
    
  end
  
  private
  
  def expect_invalid_percentage(attribute, value)
    @model.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).with(attribute, "%{attribute} must be a number between 0 and 100.")
  end
  
  def expect_valid_percentage(attribute, value)
    @model.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).with(attribute, "%{attribute} must be a number between 0 and 100.").never
  end
  
  def expect_invalid_amount(attribute, value)
    @model.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).with(attribute, "%{attribute} must be an amount greater than 0.")
  end
  
  def expect_valid_amount(attribute, value)
    @model.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).with(attribute, "%{attribute} must be an amount greater than 0.").never
  end
  
  def expect_present(attribute, value, message)
    @model.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).with(attribute, message)
  end
  
  def expect_blank(attribute, value)
    @model.expects(:value_of).with(attribute).returns(nil)
    @errors.expects(:add).never
  end
  
  def expect_not_false(attribute, value, message)
    @model.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).with(attribute, message)
  end
  
  def expect_false(attribute, value)
    @model.expects(:value_of).with(attribute).returns(value)
    @errors.expects(:add).never
  end
  
  def expect_not_sum(attributes, expected_sum, message)
    attributes.each do |attribute|
      @model.expects(:value_of).with(attribute).returns(0)
    end
    @errors.expects(:add).with(:base, message)
  end
  
  def expect_sum(attributes, expected_sum)
    atttribute_value = expected_sum / attributes.size
    attributes.each do |attribute|
      @model.expects(:value_of).with(attribute).returns(atttribute_value)
    end
    @errors.expects(:add).never
  end
  
end
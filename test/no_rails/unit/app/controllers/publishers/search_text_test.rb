require File.dirname(__FILE__) + "/../../controllers_helper"

# hydra class Publishers::SearchTextTest
module Publishers
  class SearchTextTest < Test::Unit::TestCase
    should "to_s should be text" do
      assert_equal "deals33", Publishers::SearchText.new("deals33").to_s
    end

    should "text should be striped" do
      assert_equal "deals 33", Publishers::SearchText.new("  deals 33    ").to_s
    end

    should "text can be blank" do
      assert_equal "", Publishers::SearchText.new("").to_s
    end

    should "text can be nil" do
      assert_equal "", Publishers::SearchText.new(nil).to_s
    end
    
    should "delegate blank? to @text" do
      assert Publishers::SearchText.new(nil).blank?
      assert Publishers::SearchText.new("").blank?
      assert Publishers::SearchText.new("   ").blank?
      assert !Publishers::SearchText.new("f").blank?
      assert !Publishers::SearchText.new("foobar").blank?
    end
    
    should "delegate present? to @text" do
      assert !Publishers::SearchText.new(nil).present?
      assert !Publishers::SearchText.new("").present?
      assert !Publishers::SearchText.new("   ").present?
      assert Publishers::SearchText.new("f").present?
      assert Publishers::SearchText.new("foobar").present?
    end
    
    should "delegate split to @text" do
      assert_equal [], Publishers::SearchText.new(nil).split
      assert_equal [], Publishers::SearchText.new("").split
      assert_equal [], Publishers::SearchText.new("   ").split
      assert_equal ["f"], Publishers::SearchText.new("f").split
      assert_equal ["foobar"], Publishers::SearchText.new("foobar").split
    end
    
    should "text must be at least two characters to be valid" do
      assert !Publishers::SearchText.new(nil).valid_length?
      assert !Publishers::SearchText.new("").valid_length?
      assert !Publishers::SearchText.new("   ").valid_length?
      assert !Publishers::SearchText.new("f").valid_length?
      assert !Publishers::SearchText.new("*").valid_length?
      assert Publishers::SearchText.new("foobar").valid_length?
    end
    
    should "recognize * as a wildcard" do
      assert !Publishers::SearchText.new(nil).wildcard?
      assert !Publishers::SearchText.new("").wildcard?
      assert !Publishers::SearchText.new("   ").wildcard?
      assert !Publishers::SearchText.new("f").wildcard?
      assert Publishers::SearchText.new("*").wildcard?
      assert Publishers::SearchText.new("  *  ").wildcard?
      assert !Publishers::SearchText.new("foobar").wildcard?
    end
  end
end

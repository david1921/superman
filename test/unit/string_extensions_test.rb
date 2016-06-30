require File.dirname(__FILE__) + "/../test_helper"

class StringExtensionsTest < ActiveSupport::TestCase
  def test_phone_digits
    assert_equal("16051629100", "(605) 162-9100".phone_digits, "(605) 162-9100")
    assert_equal("16051629100", "1 (605) 162-9100".phone_digits, "1 (605) 162-9100")
    assert_equal("16051629100", "6051629100".phone_digits, "6051629100")
    assert_equal("16051629100", "16051629100".phone_digits, "16051629100")
    assert_equal("16051629100", "16051629100".phone_digits, "605.162.9100")
    assert_equal("16051629100", "16051629100".phone_digits, "  1 605 162 9100   ")  
    assert_equal("", "".phone_digits, "''")
    assert_equal(nil, nil.phone_digits, nil)
  end
  
  def test_with_indefinite_article
    assert_equal "an apple", "apple".with_indefinite_article
    assert_equal "a book", "book".with_indefinite_article
    assert_equal "", "".with_indefinite_article
  end

  def test_to_ascii
    assert_equal "apple", "apple".to_ascii
    assert_equal "Best in the Tampa Bay/Sarasota Area", "“Best in the Tampa Bay/Sarasota Area”".to_ascii
  end

  def test_to_ascii_transliterate
    assert_equal "apple", "apple".to_ascii(true)
    assert_equal "\"Best in the Tampa Bay/Sarasota Area\"", "“Best in the Tampa Bay/Sarasota Area”".to_ascii(true)
  end
end

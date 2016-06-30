require File.dirname(__FILE__) + "/../../test_helper"

class PaginationHelperTest < ActionView::TestCase
  def test_range_formatter_new_with_bad_arguments
    assert_equal 1..1,  RangeFormatter.new(0, 1).index_range
    assert_equal 1..1,  RangeFormatter.new(1, 2).index_range
    assert_equal 1..1,  RangeFormatter.new(-1, 1).index_range
    assert_equal 1..1,  RangeFormatter.new(1, -1).index_range
  end

  def test_range_formatter_index_range_with_one_page
    assert_equal 1..1, RangeFormatter.new(1, 1).index_range
  end
  
  def test_range_formatter_index_range_with_six_pages
    1.upto(6) { |i| assert_equal 1..6, RangeFormatter.new(6, i).index_range }
  end
  
  def test_range_formatter_index_range_with_ten_pages
    assert_equal 1..6,  RangeFormatter.new(10, 1).index_range
    assert_equal 1..6,  RangeFormatter.new(10, 2).index_range
    assert_equal 1..6,  RangeFormatter.new(10, 3).index_range
    assert_equal 1..6,  RangeFormatter.new(10, 4).index_range
    assert_equal 2..7,  RangeFormatter.new(10, 5).index_range
    assert_equal 3..8,  RangeFormatter.new(10, 6).index_range
    assert_equal 4..9,  RangeFormatter.new(10, 7).index_range
    assert_equal 5..10, RangeFormatter.new(10, 8).index_range
    assert_equal 5..10, RangeFormatter.new(10, 9).index_range
    assert_equal 5..10, RangeFormatter.new(10, 10).index_range
  end
  
  def test_range_formatter_text_for_with_one_page
    assert_equal "1", RangeFormatter.new(1, 1).text_for(1)
    assert_equal "1", RangeFormatter.new(1, 1).text_for(0)
    assert_equal "1", RangeFormatter.new(1, 1).text_for(2)
  end

  def test_range_formatter_text_for_with_ten_pages
    1.upto(5) { |i| assert_equal i.to_s, RangeFormatter.new(10, 3).text_for(i) }
    assert_equal "6",  RangeFormatter.new(10, 3).text_for(6)
    assert_equal "3",  RangeFormatter.new(10, 3).text_for(3)
    
    assert_equal "5",  RangeFormatter.new(10, 8).text_for(4)
    assert_equal "5",  RangeFormatter.new(10, 8).text_for(5)
    6.upto(10) { |i| assert_equal i.to_s, RangeFormatter.new(10, 8).text_for(i) }
  end
  
  def test_page_size_from_param
    assert_equal 4, page_size_from_param(nil), "nil"
    assert_equal 4, page_size_from_param(""), "''"
    assert_equal 2, page_size_from_param("2"), "2"
    assert_equal 4, page_size_from_param("foo"), "foo"
    assert_equal 12, page_size_from_param("12-foo"), "12-foo"
  end
end

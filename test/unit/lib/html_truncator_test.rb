require File.dirname(__FILE__) + "/../../test_helper"
require File.dirname(__FILE__) + "/../../../lib/html_truncator"

class HtmlTruncatorTest < ActiveSupport::TestCase 
            
  test "nil text" do
    assert_nil HtmlTruncator.truncate_html(nil)
  end                                              
  
  test "no truncate needed" do
    assert_equal "<p>hello</p>", HtmlTruncator.truncate_html("<p>hello</p>", 1000)
  end

  test "simple truncation preserves html validity" do
    assert_equal "<p>hello</p>...", HtmlTruncator.truncate_html("<p>hello</p>\n<p>hello</p>\n", 15)
  end
    
  test "truncation preserves html validity with two hellos" do
    assert_equal "<p>hello</p><p>hello</p>...", HtmlTruncator.truncate_html("<p>hello</p><p>hello</p><p>hello</p>", 28)
  end  
  
  test "newlines parsed but stripped between nodes" do
    assert_equal "<p>hello</p><p>hello</p>...", HtmlTruncator.truncate_html("<p>hello</p>\n<p>hello</p>\n<p>hello</p>", 28)
  end
  
  test "truncation excludes parent if child pushes past limit" do
    nested = "<p>Top</p><div><div><p>nested1</p></div><div><p>nested2</p></div><div><p>nested3</p></div</div>"  
    assert_equal "<p>Top</p>...", HtmlTruncator.truncate_html(nested, 72)
  end

  test "truncate with arbitrary entities" do
    force_truncation = "blah"*1000
    html = "<p>foo&#1;&#12;&#123;&#1234;&#12345;&#123456;bar</p><p>#{force_truncation}</p>"
    expected = "<p>foobar</p>..."
    assert_equal expected, HtmlTruncator.truncate_html(html, 1000)
  end
  
  test "first paragraph longer than truncation length" do
    html = "<p>#{'a'*40}</p>"
    expected = "<p>aaaaaaaaaa...</p>"
    assert_equal expected, HtmlTruncator.truncate_html(html, 20)
  end  
  
end
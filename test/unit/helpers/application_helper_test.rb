require File.dirname(__FILE__) + "/../../test_helper"

class ApplicationHelperTest < ActionView::TestCase
  
  test "link_to_unescaped" do
    assert_equal %Q(<a href="http://example.com?one=1&two=2">Test</a>), link_to_unescaped("Test", "http://example.com?one=1&two=2")
    assert_equal %Q(<a href="http://example.com?one=1&two=2" id="x">Test</a>), link_to_unescaped("Test", "http://example.com?one=1&two=2", :id => "x")
    assert_equal %Q(<a href="http://example.com?one=1&two=2" id="x">http://example.com?one=1&two=2</a>), link_to_unescaped(nil, "http://example.com?one=1&two=2", :id => "x")
  end
  
  test "neutralize url" do
    assert_equal "//daily-deals.aa.com/foo/bar.jpg", protocol_relative_url("http://daily-deals.aa.com/foo/bar.jpg")
    assert_equal "//daily-deals.aa.com/foo/bar.jpg", protocol_relative_url("https://daily-deals.aa.com/foo/bar.jpg")
    assert_equal "//daily-deals.aa.com/foo/bar.jpg", protocol_relative_url("//daily-deals.aa.com/foo/bar.jpg")
  end
  
  context "localized_date" do
    
    setup do
      Timecop.freeze(Time.zone.local(2011, 8, 22, 11, 28, 19)) do
        @date = Time.zone.now.to_date
        @datetime = Time.zone.now
      end
    end
    
    context "in locale 'en'" do
      
      setup do
        I18n.locale = 'en'
      end
      
      should "output a date value as in a format like 'Monday, August 22, 2011'" do
        assert_equal 'Monday, August 22, 2011', localized_date(@date)
      end
      
      should "output a datetime in a format like 'Monday, August 22, 2011'" do
        assert_equal 'Monday, August 22, 2011', localized_date(@datetime)
      end
      
      should "output the string 'now' using the current date in Time.zone" do
        Timecop.freeze(Time.zone.local(2011, 8, 22, 11, 28, 19)) do
          assert_equal 'Monday, August 22, 2011', localized_date("now")
        end
      end
      
    end
    
    context "in locale 'es-MX'" do

      setup do
        I18n.locale = 'es-MX'
      end
      
      should "output a date value as in a format like 'lunes 22 de agosto de 2011'" do
        assert_equal 'lunes 22 de agosto de 2011', localized_date(@date)
      end
      
      should "output a datetime in a format like 'lunes 22 de agosto de 2011'" do
        assert_equal 'lunes 22 de agosto de 2011', localized_date(@datetime)
      end

      should "output the string 'now' using the current date in Time.zone" do
        Timecop.freeze(Time.zone.local(2011, 8, 22, 11, 28, 19)) do
          assert_equal 'lunes 22 de agosto de 2011', localized_date("now")
        end
      end

    end
    
  end
  
end

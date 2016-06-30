require File.dirname(__FILE__) + "/../test_helper"

class AnalyticsTagTest < ActiveSupport::TestCase 
  test "create" do
    analytics_tag = AnalyticsTag.new
    assert !analytics_tag.landing?, "Should not have a landing event yet"
    assert !analytics_tag.signup?, "Should not have a signup event yet"
    assert !analytics_tag.sale?, "Should not have a sale event yet"
  end
  
  test "landing" do
    analytics_tag = AnalyticsTag.new

    analytics_tag.landing!
    assert  analytics_tag.landing?, "Should have a landing event"
    assert !analytics_tag.signup?, "Should not have a signup event"
    assert !analytics_tag.sale?, "Should not have a sale event"
  end
  
  test "signup" do
    analytics_tag = AnalyticsTag.new

    analytics_tag.signup!
    assert !analytics_tag.landing?, "Should not have a landing event"
    assert  analytics_tag.signup?, "Should have a signup event"
    assert !analytics_tag.sale?, "Should not have a sale event"
  end

  test "presale" do
    analytics_tag = AnalyticsTag.new
    analytics_tag.presale!
    assert !analytics_tag.landing?, "Should not have a landing event"
    assert  analytics_tag.presale?, "Should have a signup event"
    assert !analytics_tag.sale?, "Should not have a sale event"
  end
  
  test "sale with default data" do
    analytics_tag = AnalyticsTag.new

    analytics_tag.sale!
    assert !analytics_tag.landing?, "Should not have a landing event"
    assert !analytics_tag.signup?, "Should not have a signup event"
    assert  analytics_tag.sale?, "Should have a sale event"

    assert_not_nil analytics_tag.data
    assert_equal 0.00, analytics_tag.data.value
    assert_equal 0, analytics_tag.data.quantity
    assert_nil analytics_tag.data.item_id
    assert_nil analytics_tag.data.sale_id
  end
  
  test "sale with specified data" do
    analytics_tag = AnalyticsTag.new

    analytics_tag.sale! :value => 1.23, :quantity => 2, :item_id => "1234", :sale_id => "9876"
    assert !analytics_tag.landing?, "Should not have a landing event"
    assert !analytics_tag.signup?, "Should not have a signup event"
    assert  analytics_tag.sale?, "Should have a sale event"

    assert_not_nil analytics_tag.data
    assert_equal 1.23, analytics_tag.data.value
    assert_equal 2, analytics_tag.data.quantity
    assert_equal "1234", analytics_tag.data.item_id
    assert_equal "9876", analytics_tag.data.sale_id
  end
end

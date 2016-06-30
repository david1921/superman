require File.dirname(__FILE__) + "/../../../test_helper"

class NumberFiltersTest < ActiveSupport::TestCase

  def test_currency_filter
    assert_equal "$50", Liquid::Template.parse("{{ 50 | currency }}").render
    assert_equal "$50.00", Liquid::Template.parse("{{ 50 | currency: 2 }}").render
  end
  
  def test_number_filter
    assert_equal "50", Liquid::Template.parse("{{ 50 | number }}").render
    assert_equal "50.00", Liquid::Template.parse("{{ 50 | number: 2 }}").render    
  end
  
  def test_whole_part_filter
    assert_equal "20", Liquid::Template.parse("{{ 20 | whole_part }}").render
    assert_equal "15", Liquid::Template.parse("{{ 15.99 | whole_part }}").render
  end
  
  def test_dollars_filter
    assert_equal "20", Liquid::Template.parse("{{ 20 | dollars }}").render
    assert_equal "15", Liquid::Template.parse("{{ 15.99 | dollars }}").render
  end
  
  def test_decimal_part_filter
    assert_equal "05", Liquid::Template.parse("{{ 15.05 | decimal_part }}").render
    assert_equal "99", Liquid::Template.parse("{{ 15.99 | decimal_part }}").render
  end
  
  def test_cents_filter
    assert_equal "05", Liquid::Template.parse("{{ 15.05 | cents }}").render
    assert_equal "99", Liquid::Template.parse("{{ 15.99 | cents }}").render
  end

  test "less_than filter" do
    assert_equal ".true",  Liquid::Template.parse("{{ 3 | less_than: 4, '.true', '.false' }}").render
    assert_equal ".false", Liquid::Template.parse("{{ 3 | less_than: 2, '.true', '.false' }}").render

    assert_equal "", Liquid::Template.parse("{{ 3 | less_than: 2, '.true' }}").render
    assert_equal "<div class=\"\">", Liquid::Template.parse("<div class=\"{{ 3 | less_than: 2, '.true' }}\">").render
  end

  test "greater_than filter" do
    assert_equal ".true",  Liquid::Template.parse("{{ 3 | greater_than: 2, '.true', '.false' }}").render
    assert_equal ".false", Liquid::Template.parse("{{ 3 | greater_than: 4, '.true', '.false' }}").render

    assert_equal "", Liquid::Template.parse("{{ 1 | greater_than: 2, '.true' }}").render
    assert_equal "<div class=\"\">", Liquid::Template.parse("<div class=\"{{ 3 | greater_than: 4, '.true' }}\">").render
  end

  test "es locale should format numbers with correct separator and delimiter" do
    I18n.locale = :es

    assert_equal "$50", Liquid::Template.parse("{{ 50 | currency }}").render
    assert_equal "$50,00", Liquid::Template.parse("{{ 50 | currency: 2 }}").render

    assert_equal "50", Liquid::Template.parse("{{ 50 | number }}").render
    assert_equal "50,00", Liquid::Template.parse("{{ 50 | number: 2 }}").render    
  end

end

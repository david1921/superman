require File.dirname(__FILE__) + "/../../../test_helper"

class NydnGetTransitDirectionsFilterTest < ActiveSupport::TestCase

  def test_nydn_get_transit_directions
    advertiser = Factory :advertiser
    assert advertiser.address?
    assert_match %r{<a href="http://hopstop.nydailynews.com/},
                 Liquid::Template.parse("{{ advertiser | nydn_get_transit_directions }}").render("advertiser" => advertiser)
  end
  
end
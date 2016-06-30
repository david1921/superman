require File.dirname(__FILE__) + "/../test_helper"

class AnalyticsProviderTest < ActiveSupport::TestCase 

   
  def test_accepts_valid_analytics_provider_on_initialize
    assert_equal nil, new_analytic_tracker(1, "presst").errors.on(:id)
  end
  
  def test_rejects_missing_analytics_provider_on_initialize
    assert_equal "Id doesn't exist", new_analytic_tracker.errors.on(:id)
  end
  
  def test_rejects_invalid_analytics_provider_on_initialize
    assert_equal "Id doesn't exist", new_analytic_tracker(12, "presst").errors.on(:id)
  end
  
  def test_returns_the_analytics_provider_name
    assert_equal "SiteCatalyst", new_analytic_tracker(1, "presst").name
  end
  
  def test_returns_the_analytics_provider_site_id
    assert_equal "presst", new_analytic_tracker(1, "presst").site_id
  end
  
  def test_returns_the_analytics_provider_partial
    assert_equal "/shared/site_catalyst", new_analytic_tracker(1, "presst").partial
  end

private

  def new_analytic_tracker(id = nil, site_id = nil)
    AnalyticsProvider.new(:id => id, :site_id => site_id)
  end

end

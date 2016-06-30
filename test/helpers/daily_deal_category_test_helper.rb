module DailyDealCategoryTestHelper
  
  def setup_analytics_categories
    analytics_categories = [
      ["Activities", "A"], ["Beauty", "B"], ["Dining", "D"], ["Membership", "M"],
      ["Merchandise/Service", "MS"], ["Other", "O"], ["Publisher Subscription", "PS"],
      ["Theater", "TH"], ["Tourism", "T"]]
      
    analytics_categories.each do |ac|
      DailyDealCategory.create! :name => ac[0], :abbreviation => ac[1]
    end
  end

end
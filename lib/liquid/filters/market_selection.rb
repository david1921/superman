module Liquid
  module Filters
    module MarketSelection
      # this is automatically loaded in views, but not in other contexts such as
      # tests
      include MarketSelectionHelper
    end
  end
end

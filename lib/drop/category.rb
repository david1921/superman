module Drop
  class Category < Liquid::Drop
    
    delegate :name, :offers_count, :id, :to => :category
    
    def initialize(category)
      @category = category
    end

    private
    
    def category
      @category
    end
    
  end
end
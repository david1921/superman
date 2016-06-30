class Syndication::SearchResponse

  attr_reader :deals
  
  delegate :current_page, :to => :deals
  
  def initialize(*args)
    settings = args.pop 
    @deals = settings[:deals]
  end
  
  def results?
    @deals.try(:length) > 0
  end
  
  def match(&block) 
    if block_given?
      matching_deals = deals.collect{|d| d if yield d}.compact
      self.class.new( :deals => matching_deals )
    else
      self # if no block is given, then return self
    end
  end
  
end

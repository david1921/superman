class AnalyticsTag
  class LandingData; end
  
  class SignupData; end
  
  class PresignupData; end
  
  class SweepstakesSignupData; end
  
  class PreSaleData; end

  class SaleData
    attr_reader :value, :quantity, :item_id, :sale_id

    def initialize(options)
      @value, @quantity, @item_id, @sale_id = { :value => 0.00, :quantity => 0 }.merge(options).values_at(:value, :quantity, :item_id, :sale_id)
    end
  end
  
  attr_reader :data
  
  def landing!
    @data = LandingData.new
    self
  end
  
  def landing?
    @data.is_a?(LandingData)
  end

  def signup!
    @data = SignupData.new
    self
  end
  
  def signup?
    @data.is_a?(SignupData)
  end

  def sale!(options = {})
    @data = SaleData.new(options)
    self
  end
  
  def sale?
    @data.is_a?(SaleData)
  end  
  
  def presale!
    @data = PreSaleData.new
    self
  end

  def presale?
    @data.is_a?(PreSaleData)
  end
  
  def presignup!
    @data = PresignupData.new
    self
  end
  def presignup?
    @data.is_a?(PresignupData)
  end

  def sweepstakes_signup!
    @data = SweepstakesSignupData.new
    self
  end
  
  def sweepstakes_signup?
    @data.is_a?(SweepstakesSignupData)
  end


end

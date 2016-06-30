module Drop
  class Country < Liquid::Drop
    delegate :code,
             :name,
             :to => :country,
             :allow_nil => true

    def initialize(country)
      @country = country
    end

    private

    def country
      @country
    end
  end
end


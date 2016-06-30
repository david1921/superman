module Drop
  class Logo < Liquid::Drop
    delegate :file?,
             :to_file,
             :to => :logo

    def initialize(logo)
      @logo = logo
    end
    
    def standard_url
      logo.url :standard
    end

    def normal_url
      logo.url :normal
    end
    
    def thumbnail_url
      logo.url :thumbnail
    end
    
    def square_url
      logo.url :square
    end
    
    def url
      logo.url
    end
    
    private
    
    def logo
      @logo
    end
  end
end

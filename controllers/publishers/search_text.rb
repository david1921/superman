module Publishers
  class SearchText
    attr_reader :text
    delegate :blank?, :present?, :split, :to_s, :to => :text

    def initialize(text)
      @text = text.try(:strip) || ""
    end
  
    def valid_length?
      @text.present? && @text.size > 1
    end
  
    def wildcard?
      @text == "*"
    end
  end
end

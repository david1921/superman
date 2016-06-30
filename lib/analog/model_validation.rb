module Analog
  module ModelValidation
    
    def validate_percentage(attribute)
      value = value_of(attribute)
      errors.add(attribute, "%{attribute} must be a number between 0 and 100.") unless (0..100).include?(value)
    end
    
    def validate_amount(attribute)
      value = value_of(attribute)
      errors.add(attribute, "%{attribute} must be an amount greater than 0.") unless value.present? && value > 0
    end
    
    def validate_blank(attribute, message)
      value = value_of(attribute)
      errors.add(attribute, message) unless value.blank?
    end
    
    def validate_false(attribute, message)
      value = value_of(attribute)
      errors.add(attribute, message) unless value == false
    end
    
    def validate_sum(attributes, expected_sum, message)
      sum = 0
      attributes.each do |attribute|
        value = value_of(attribute)
        sum = sum + value unless value.nil?
      end
      errors.add(:base, message) unless sum == expected_sum
    end
    
    def value_of(attribute)
      self.respond_to?(attribute.to_s) ? self.send(attribute.to_s) : self[attribute.to_s]
    end
    
  end
end
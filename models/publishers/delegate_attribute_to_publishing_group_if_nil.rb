module Publishers
  module DelegateAttributeToPublishingGroupIfNil

    def delegate_attribute_to_publishing_group_if_nil(publisher_attribute, options = {})
      publishing_group_attribute = options[:publishing_group_attribute] || publisher_attribute
      boolean_attribute = options[:boolean_attribute]
      define_delegate_method_by_attribute_name(publisher_attribute, publishing_group_attribute)
      if boolean_attribute
        delegate_method = (publisher_attribute.to_s << "?").to_sym
        define_delegate_method(delegate_method, publisher_attribute, publishing_group_attribute)
      end
    end
    
    def define_delegate_method(delegate_method, publisher_attribute, publishing_group_attribute)
      define_method(delegate_method) do
        result = read_attribute(publisher_attribute)
        if publishing_group.present? and result.nil?
          result ||= publishing_group.send(publishing_group_attribute) 
        end
        result
      end
    end
    
    def define_delegate_method_by_attribute_name(publisher_attribute, publishing_group_attribute)
      define_delegate_method(publisher_attribute, publisher_attribute, publishing_group_attribute)
    end
  end
end

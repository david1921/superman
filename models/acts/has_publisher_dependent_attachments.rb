module HasPublisherDependentAttachments
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def publisher_dependent_attachment_styles(config)
      Proc.new do |attachment|
        {}.tap do |hash|
          config.each do |style, attrs|
            hash[style] = { :geometry => attachment_style_geometry(attachment.name, style, attrs[:geometry]) }.merge(attrs.except(:geometry))
          end
        end
      end
    end
    
    private
  
    def attachment_style_geometry(attachment_name, style, default)
      Proc.new do |instance|
        class_key = name.underscore.to_sym
        #
        # Work around erroneous calls with argument of type Paperclip::Attachment from PaperClip::Style#processor_options.
        #
        instance.respond_to?(:publisher) && (instance.publisher.try(:attachment_style_geometry, class_key, attachment_name, style) || default)
      end
    end
  end
end

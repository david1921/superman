module HasListing

  def self.included(base)
    base.send :extend, ClassMethods
  end
       
  module ClassMethods
    def validates_listing(options={})
      scope = options[:unique_scope]
      with_options :if => :listing? do |thing_with_listing|
        thing_with_listing.validates_presence_of :listing
        thing_with_listing.validates_uniqueness_of :listing, :scope => scope, :allow_blank => true
      end
    end
  end
  
  def listing?   
    raise "Must have publisher to include HasListing" unless respond_to?(:publisher)
    publisher.try("#{self.class.name.downcase}_has_listing?")
  end

end
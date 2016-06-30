module ActsAsSoftDeletable
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do

      named_scope :not_deleted, :conditions => { "#{table_name}.deleted_at" => nil }
      named_scope :deleted,     :conditions => "#{table_name}.deleted_at is not null"
      
      alias_method :mark_as_deleted!, :delete!
      alias_method :soft_delete!, :delete!
      
    end
  end
  
  module InstanceMethods
    
    def deleted?
      deleted_at.present? && deleted_at <= Time.zone.now
    end

    def delete!
      if deleted_at.nil?
        self.deleted_at = Time.zone.now
        if save_with_validation false
          after_soft_deletion # a callback to handle any other actions after the deletion takes place
          return true
        end
      else
        true
      end
    end
    
    def undelete!
      update_attributes!(:deleted_at => nil)
    end
    
    # implement this method on the model if
    # you need to handle some behaviour after
    # a soft deletion takes place.
    def after_soft_deletion
    end
    
  end
  
end

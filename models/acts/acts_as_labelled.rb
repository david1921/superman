module ActsAsLabelled
  def self.included(base)
    base.send :include, InstanceMethods
    base.send :extend, ClassMethods
    base.class_eval do
      before_validation :normalize_label
      validates_uniqueness_of :label, :allow_nil => true
      validates_format_of :label, :with => /\A[A-Za-z0-9\-]+\Z/, :message => "'%{value}' is invalid. Use only letters, numbers, and dashes.", :allow_nil => true
      named_scope :name_or_label_like, lambda { |text|
        { :conditions => [ "(name like :text or label like :text)", { :text => "%#{text}%" } ] }
      }
    end
  end

  module ClassMethods
    def find_by_label_or_id(id_or_label)
      return nil if id_or_label.blank?
      if id_or_label =~ /^\d+$/ and id_or_label.to_i > 0
        find id_or_label
      else
        find_by_label id_or_label
      end
    end

    def find_by_label_or_id!(id_or_label)
      find_by_label_or_id(id_or_label) or raise ActiveRecord::RecordNotFound
    end
  end

  module InstanceMethods

    private
    
    def normalize_label
      self.label.try(:strip!)
      self.label = nil if label.blank?
    end
  end
end

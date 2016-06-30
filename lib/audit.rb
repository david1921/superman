module Audit
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include InstanceMethods
    end
  end

  module ClassMethods

    # Verison attributes on the give class.  If no 
    # options are given, then all database attributes will
    # be versioned.
    #
    # You can also supply :only or :except options
    # to only version certain attributes.
    #
    # If there is a current user stored in the current Thread
    # it will be recorded with the version record.
    def audited(options = {}, &block)      
      after_create  :create_initial_version_if_necessary
      before_save   :set_updated_by

      initial_version = options.delete(:initial_version)
      versioned options, &block
      prepare_versioned_options( :initial_version => initial_version ) if initial_version
    end


    # Adds version support for the translation tables.  Instead
    # of calling: 
    #
    #   translates :attribute_name 
    #
    # you can call:
    #
    #   audited_translations :attribute_name.
    #
    def audited_translations(*fields)
      translates *fields
      translation_class.class_eval do
        audited
      end
    end

  end

  module InstanceMethods
    def last_author_for(column)
      versions.reverse.detect {|v| v.changes.has_key?(column.to_s)}.try(:user)
    end

    private

    def set_updated_by
      @updated_by = User.current
    end

    # this is a patch for Vestal Versions to create an initial version.
    # once we upgrade to Rails 3, we can use a more recent version of 
    # Vestal Version which provides this functionality.
    def create_initial_version_if_necessary
      if self.class.vestal_versions_options[:initial_version]
        # the Rails 3 version will implement create_initial_version? if so
        # then we let it do it's thing.
        unless self.private_methods.include?(:create_initial_version?.to_s)
          versions.create({:changes => version_changes, :number => 1, :user => User.current})
          reset_version_changes
          reset_version          
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, Audit) if defined?(ActiveRecord)

module ReadyMadeThemes
  
  READY_MADE_THEME_NAMES = ["howlingwolf", "roaringlion", "cleverbetta", "prowlingpanther", "howlingwolfoptimized", "leapinggazelle", "dramaticchipmunk", "prowlingpantheroptimized", ""]
  
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
    
    base.validates_inclusion_of :parent_theme, :in => READY_MADE_THEME_NAMES, :allow_nil => true,
                                :message => "is not a valid theme"
  end
  
  module ClassMethods

    def ready_made_theme_names
      READY_MADE_THEME_NAMES
    end

  end
  
  module InstanceMethods

    def uses_a_ready_made_theme?
      parent_theme.present?
    end
    
  end
    
end

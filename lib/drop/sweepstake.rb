module Drop
  class Sweepstake < Liquid::Drop
    include ActionController::UrlWriter
    
    delegate :id,
             :value_proposition,
             :value_proposition_subhead,
             :description,
             :short_description,
             :terms, 
             :official_rules,
             :publisher,
             :promotional_opt_in_text,
             :show_promotional_opt_in_checkbox?,
             :featured?,
             :to => :sweepstake

    def initialize(sweepstake)
      @sweepstake = sweepstake
    end
    
    def full_photo_url
      sweepstake.photo.url(:full)
    end
    
    def medium_photo_url
      sweepstake.photo.url(:medium)
    end
    
    def full_logo_url
      sweepstake.logo.url(:full)
    end
    
    def full_logo_alternate_url
      sweepstake.logo_alternate.url(:full)
    end
    
    def public_url
      publisher_sweepstake_url(publisher.label, sweepstake, :host => publisher.daily_deal_host)
    end
    
    def entries_path
      publisher_sweepstake_entries_path(publisher.label, sweepstake)
    end
    
    def official_rules_path
      official_rules_publisher_sweepstake_path(publisher.label, sweepstake)
    end
    
    def is_sweepstake_page?
      if @context.present? && @context.registers.present?
        (@context.registers[:controller] == 'sweepstake' && @context.registers[:action] == 'show')
      else
        false
      end
    end
    
    def description_exists?
      !@sweepstake.description.empty?
    end
    def short_description_exists?
      !@sweepstake.short_description.empty?
    end
    private
    
    def sweepstake
      @sweepstake
    end
    
    
  end
end
module TimeWarnerCable
  
  # Responsible for setting up the infrastructure for hiding/showing the 
  # TWC logo, based on the refering site.
  module Logo

    # NOTE: since this is being included on ApplicationController, and the before_filter
    # is being prepended before all the publisher look ups.  THERE might be a better way to 
    # do this.  Just getting it working for now.
    
    if Rails.env.production?
      VALID_INTERNAL_TWC_HOSTS = ["deals.clickedin.com", "offers.clickedin.com"]
    else
      VALID_INTERNAL_TWC_HOSTS = [
        "deals.clickedin.com",
        "offers.clickedin.com",
        "staging.analoganalytics.com",
        "staging.analoganalytics.net",
        "nightly.analoganalytics.com",
        "nightly.analoganalytics.net",
        "localhost"
      ]
    end
        
    VALID_EXTERNAL_TWC_DOMAINS = ["timewarnercable.com", "rr.com", "ny1.com", "ynn.com", "news14.com"]    
    #
    # See http://stackoverflow.com/questions/983158/remove-subdomain-from-string-in-ruby
    #
    RE_DOMAIN_EXTRACTION = /^(?:(?>[a-z0-9-]*\.)+?|)([a-z0-9-]+\.(?>[a-z]*(?>\.[a-z]{2})?))$/i
        
    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        before_filter :set_show_twc_logo_cookie
        helper_method :show_twc_logo?
      end
    end
    
    module InstanceMethods
    
      def set_show_twc_logo_cookie
        if external_referer?
          if time_warner_cable_referer?
            cookies[:show_twc_logo] = "true" unless "true" == cookies[:show_twc_logo]
          else
            cookies.delete :show_twc_logo if cookies[:show_twc_logo]
          end
        end
      rescue Exception => e
        logger.debug "set_show_twc_logo_cookie error: #{e}"
      end
      
      def show_twc_logo?
        "true" == cookies[:show_twc_logo]
      end
      
      private
      
      def referer_host
        @referer_host ||= (params[:host] || URI.parse(request.referer).host)
      end

      def referer_domain
        @referer_domain ||= (params[:domain] || referer_host.gsub(RE_DOMAIN_EXTRACTION, '\1').strip)
      end
    
      def external_referer?
        !VALID_INTERNAL_TWC_HOSTS.include?(referer_host) rescue false
      end

      def time_warner_cable_referer?
        VALID_EXTERNAL_TWC_DOMAINS.include?(referer_domain) rescue false
      end
    end
      
  end
end
